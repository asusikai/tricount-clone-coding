import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';
import 'bootstrap/bootstrap_error_page.dart';
import 'common/services/auth_service.dart';
import 'config/environment.dart';
import 'core/auth/auth_callback_handler.dart';
import 'core/auth/auth_state_manager.dart';
import 'core/config/env_validator.dart';
import 'core/constants/constants.dart';
import 'core/deep_link/deep_link_handler.dart';
import 'core/error/error_mapper.dart';
import 'core/invite/invite_handler.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(
    () async {
      FlutterError.onError = (FlutterErrorDetails details) {
        Zone.current.handleUncaughtError(
          details.exception,
          details.stack ?? StackTrace.empty,
        );
      };

      runApp(const _BootstrapApp());
    },
    (Object error, StackTrace stackTrace) {
      debugPrint('Unhandled zone error: $error');
      debugPrint(stackTrace.toString());
    },
  );
}

enum _BootstrapStatus { initializing, ready, failed }

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  _BootstrapStatus _status = _BootstrapStatus.initializing;
  String? _errorMessage;
  Object? _lastError;
  StackTrace? _lastStackTrace;
  bool _bootstrapping = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapping) {
      return;
    }
    _bootstrapping = true;
    setState(() {
      _status = _BootstrapStatus.initializing;
      _errorMessage = null;
      _lastError = null;
      _lastStackTrace = null;
    });

    try {
      await Environment.load();
      Environment.ensureSupabase();

      // 환경 변수 및 URL 스킴 검증
      final validationResult = EnvValidator.validateAll();
      validationResult.logResults();

      if (!validationResult.isValid) {
        final issues = <String>[];
        if (!validationResult.environment.isValid) {
          issues.addAll(validationResult.environment.issues);
        }
        if (!validationResult.urlSchemes.isValid) {
          issues.add(validationResult.urlSchemes.message);
        }
        final errorMessage =
            '환경 설정 검증 실패:\n${issues.join('\n')}\n\n'
            'Android 가이드:\n${validationResult.urlSchemes.androidGuide}\n\n'
            'iOS 가이드:\n${validationResult.urlSchemes.iosGuide}';

        // ConfigError로 매핑하여 로깅
        ErrorMapper.mapAndLog(StateError(errorMessage), context: '환경 변수 검증 실패');

        throw StateError(errorMessage);
      }

      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = _BootstrapStatus.ready;
      });
    } catch (error, stackTrace) {
      debugPrint('앱 초기화 실패: $error');
      debugPrint(stackTrace.toString());

      if (!mounted) {
        return;
      }

      setState(() {
        _status = _BootstrapStatus.failed;
        _lastError = error;
        _lastStackTrace = stackTrace;
        _errorMessage = _describeBootstrapError(error);
      });
    } finally {
      _bootstrapping = false;
    }
  }

  String _describeBootstrapError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    if (error is TimeoutException) {
      return '네트워크 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.';
    }
    return '앱을 준비하는 중 오류가 발생했습니다. 다시 시도해주세요.\n($error)';
  }

  String? _technicalDetails() {
    final buffer = StringBuffer();
    if (_lastError != null) {
      buffer.writeln(_lastError);
    }
    if (_lastStackTrace != null) {
      buffer.writeln(_lastStackTrace);
    }
    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _BootstrapStatus.initializing:
        return const _BootstrapLoadingApp();
      case _BootstrapStatus.ready:
        return const ProviderScope(child: MyApp());
      case _BootstrapStatus.failed:
        return MaterialApp(
          home: BootstrapErrorPage(
            message: _errorMessage ?? '앱을 준비하는 중 알 수 없는 오류가 발생했습니다.',
            technicalDetails: _technicalDetails(),
            onRetry: _bootstrap,
          ),
        );
    }
  }
}

class _BootstrapLoadingApp extends StatelessWidget {
  const _BootstrapLoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  late final DeepLinkHandler _deepLinkHandler;
  late final AuthCallbackHandler _authCallbackHandler;
  late final InviteHandler _inviteHandler;

  @override
  void initState() {
    super.initState();
    _initializeHandlers();
    _listenToDeepLinks();
    _listenToAuthStateChanges();
  }

  void _initializeHandlers() {
    _inviteHandler = InviteHandler(
      onNavigate: _safeNavigate,
      onShowMessage: _showMessage,
      onShowError: (message, {inviteCode}) {
        _showInviteErrorSnackbar(message, inviteCode: inviteCode);
      },
    );

    _deepLinkHandler = DeepLinkHandler(
      onNavigate: _safeNavigate,
      onShowMessage: _showMessage,
      onShowError: (message, {error, stackTrace}) {
        _handleDeepLinkError(message, error: error, stackTrace: stackTrace);
      },
    );

    _authCallbackHandler = AuthCallbackHandler(
      onNavigate: _safeNavigate,
      onShowError: (message) {
        AuthService.setAuthError(message);
      },
      onProcessPendingInvites: _inviteHandler.processPendingInvites,
    );
  }

  Future<void> _listenToDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        unawaited(_handleDeepLink(initialUri));
      }
    } on FormatException catch (error, stackTrace) {
      _handleDeepLinkError(
        '잘못된 링크 형식입니다. 홈으로 이동합니다.',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _handleDeepLinkError(
        '링크를 처리할 수 없습니다. 홈으로 이동합니다.',
        error: error,
        stackTrace: stackTrace,
      );
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        unawaited(_handleDeepLink(uri));
      },
      onError: (Object error, StackTrace stackTrace) {
        _handleDeepLinkError(
          '링크 수신 중 오류가 발생했습니다. 홈으로 이동합니다.',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }

  Future<void> _handleDeepLink(Uri uri) async {
    final client = Supabase.instance.client;
    final isAuthenticated = client.auth.currentSession != null;

    // 인증 콜백 처리
    if (_authCallbackHandler.isSupportedAuthCallback(uri)) {
      await _authCallbackHandler.handle(uri, client);
      return;
    }

    // 그룹 초대 딥링크 처리
    if (_deepLinkHandler.isGroupInviteUri(uri)) {
      final inviteCode = _deepLinkHandler.parseInviteCode(uri);
      if (inviteCode == null || inviteCode.isEmpty) {
        _handleDeepLinkError(
          '유효하지 않은 초대 링크입니다.',
          error: StateError('Missing invite code: $uri'),
        );
        return;
      }

      if (_inviteHandler.isCompleted(inviteCode)) {
        _showMessage('이미 처리된 초대 링크입니다.');
        _safeNavigate(HomeTab.groups.routePath);
        return;
      }

      if (!isAuthenticated) {
        _inviteHandler.queueInviteCode(inviteCode);
        _showMessage('로그인 후 자동으로 그룹에 가입합니다.');
        _safeNavigate('/auth');
        return;
      }

      await _inviteHandler.processInviteCode(inviteCode);
      return;
    }

    // 일반 딥링크 처리
    await _deepLinkHandler.handle(uri, isAuthenticated: isAuthenticated);
  }

  void _handleDeepLinkError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (error != null) {
      debugPrint('딥링크 처리 실패: $error');
    }
    if (stackTrace != null) {
      debugPrint('딥링크 오류 스택: $stackTrace');
    }
    _showMessage(message);
    _navigateToSafeEntry();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = _scaffoldMessengerKey.currentState;
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }

  void _showInviteErrorSnackbar(String message, {String? inviteCode}) {
    if (!mounted) {
      return;
    }
    final messenger = _scaffoldMessengerKey.currentState;
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          action: inviteCode == null
              ? null
              : SnackBarAction(
                  label: '재시도',
                  onPressed: () => _inviteHandler.retryInvite(inviteCode),
                ),
        ),
      );
  }

  void _navigateToSafeEntry() {
    if (!mounted) {
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    _safeNavigate(session == null ? '/auth' : HomeTab.groups.routePath);
  }

  void _safeNavigate(String location) {
    if (!mounted) return;

    try {
      appRouter.go(location);
      debugPrint('네비게이션 성공: $location');
    } catch (e, stackTrace) {
      debugPrint('네비게이션 에러: $e');
      debugPrint('스택 트레이스: $stackTrace');
      // 네비게이션 실패도 에러로 기록
      AuthService.setAuthError('페이지 이동 중 오류가 발생했습니다: $e');

      // 다음 프레임에서 재시도
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          try {
            appRouter.go(location);
            debugPrint('네비게이션 재시도 성공: $location');
          } catch (e2, stackTrace2) {
            debugPrint('네비게이션 재시도도 실패: $e2');
            debugPrint('재시도 스택 트레이스: $stackTrace2');
            // 재시도 실패도 에러로 기록
            AuthService.setAuthError('페이지 이동 재시도 실패: $e2');
          }
        }
      });
    }
  }

  /// 로그아웃 처리
  ///
  /// 앱 상태를 초기화하고 인증 페이지로 이동합니다.
  void _handleSignOut(String currentLocation) {
    // 앱 상태 초기화 (Riverpod ref는 MyApp에서 직접 접근 불가하므로 null 전달)
    // 실제 Provider 초기화는 각 페이지에서 처리됨
    AuthStateManager.clearAppState(null);

    // 세션 만료 알림 표시 (인증 페이지가 아닌 경우)
    if (currentLocation != RouteConstants.splash &&
        currentLocation != RouteConstants.auth) {
      _showSessionExpiredMessage();
    }

    // 인증 페이지로 이동
    if (currentLocation != RouteConstants.splash &&
        currentLocation != RouteConstants.auth) {
      _safeNavigate(RouteConstants.auth);
    }
  }

  /// 세션 만료 메시지 표시
  void _showSessionExpiredMessage() {
    if (!mounted) return;
    final messenger = _scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('세션이 만료되었습니다. 다시 로그인해주세요.'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// 인증 상태 변화 구독
  ///
  /// 세션 생성/만료/갱신 시 자동으로 라우팅을 업데이트합니다.
  void _listenToAuthStateChanges() {
    final client = Supabase.instance.client;
    _authStateSubscription = client.auth.onAuthStateChange.listen(
      (AuthState state) {
        debugPrint('인증 상태 변경: ${state.event}');
        
        // 세션 정보 로깅
        final session = state.session;
        if (session != null) {
          debugPrint('세션 존재: expiresAt=${session.expiresAt}, expiresIn=${session.expiresIn}');
        } else {
          debugPrint('세션 없음');
        }

        if (!mounted) return;

        final currentLocation =
            appRouter.routerDelegate.currentConfiguration.uri.path;

        final isUserDeleted = state.event.name == 'userDeleted';
        if (isUserDeleted) {
          debugPrint('사용자 삭제 이벤트 감지');
          AuthStateManager.clearStateOnUserDeleted(null);
        }

        final normalizedEvent =
            isUserDeleted ? AuthChangeEvent.signedOut : state.event;

        switch (normalizedEvent) {
          case AuthChangeEvent.initialSession:
            // 초기 세션 로드 시는 SplashPage에서 처리하므로 무시
            debugPrint('초기 세션 로드 (SplashPage에서 처리)');
            break;
          case AuthChangeEvent.signedIn:
            // 로그인 성공 시 홈으로 이동 (SplashPage가 아닌 경우)
            debugPrint('로그인 성공: 현재 위치=$currentLocation');
            if (currentLocation != RouteConstants.splash) {
              _safeNavigate(RouteConstants.home);
            }
            break;
          case AuthChangeEvent.signedOut:
            // 로그아웃 시 앱 상태 초기화 및 인증 페이지로 이동
            debugPrint('로그아웃 이벤트: 현재 위치=$currentLocation');
            _handleSignOut(currentLocation);
            break;
          case AuthChangeEvent.tokenRefreshed:
            // 토큰 갱신 시 라우터만 리프레시 (현재 위치 유지)
            debugPrint('토큰 갱신 완료: expiresAt=${session?.expiresAt}');
            appRouter.refresh();
            break;
          case AuthChangeEvent.passwordRecovery:
          case AuthChangeEvent.userUpdated:
          case AuthChangeEvent.mfaChallengeVerified:
            // 기타 이벤트는 라우터만 리프레시
            debugPrint('기타 인증 이벤트: ${normalizedEvent.name}');
            appRouter.refresh();
            break;
          case AuthChangeEvent.userDeleted:
            // 이미 normalizedEvent가 userDeleted 인 경우 (정상 경로)
            debugPrint('사용자 삭제 처리');
            _handleSignOut(currentLocation);
            break;
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('인증 상태 구독 오류: $error');
        debugPrint('스택 트레이스: $stackTrace');
      },
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tricount Clone',
      theme: ThemeData.light(),
      scaffoldMessengerKey: _scaffoldMessengerKey,
      routerConfig: appRouter,
    );
  }
}
