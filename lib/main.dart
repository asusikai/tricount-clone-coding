import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';
import 'bootstrap/bootstrap_error_page.dart';
import 'common/services/auth_service.dart';
import 'common/services/group_service.dart';
import 'config/environment.dart';
import 'features/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      Zone.current.handleUncaughtError(
        details.exception,
        details.stack ?? StackTrace.empty,
      );
    };

    runApp(const _BootstrapApp());
  }, (Object error, StackTrace stackTrace) {
    debugPrint('Unhandled zone error: $error');
    debugPrint(stackTrace.toString());
  });
}

enum _BootstrapStatus { initializing, ready, failed }

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp({super.key});

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
            message: _errorMessage ??
                '앱을 준비하는 중 알 수 없는 오류가 발생했습니다.',
            technicalDetails: _technicalDetails(),
            onRetry: _bootstrap,
          ),
        );
    }
  }
}

class _BootstrapLoadingApp extends StatelessWidget {
  const _BootstrapLoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
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
  final Set<String> _handledAuthUris = <String>{};
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final List<String> _pendingInviteCodes = <String>[];
  final Set<String> _processingInviteCodes = <String>{};
  final Set<String> _completedInviteCodes = <String>{};

  @override
  void initState() {
    super.initState();
    _listenToDeepLinks();
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
    try {
      // 인증 콜백 처리
      if (_isSupportedAuthCallback(uri)) {
        await _handleAuthCallback(uri);
        return;
      }

      // 그룹 초대 딥링크 처리
      if (_isGroupInviteUri(uri)) {
        await _handleGroupInvite(uri);
        return;
      }

      final tabFromLink = _maybeParseHomeTabUri(uri);
      if (tabFromLink != null) {
        await _handleHomeTabLink(tabFromLink);
        return;
      }

      if (uri.scheme.toLowerCase() == 'splitbills') {
        _handleDeepLinkError(
          '지원하지 않는 링크입니다. 홈으로 이동합니다.',
          error: StateError('Unsupported splitbills link: $uri'),
        );
      }
    } on FormatException catch (error, stackTrace) {
      _handleDeepLinkError(
        '유효하지 않은 링크입니다. 홈으로 이동합니다.',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      _handleDeepLinkError(
        '링크 처리 중 오류가 발생했습니다. 홈으로 이동합니다.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleGroupInvite(Uri uri) async {
    try {
      if (!_isGroupInviteUri(uri)) {
        debugPrint('지원하지 않는 그룹 초대 링크입니다: $uri');
        return;
      }

      final inviteCode = _parseInviteCode(uri);
      if (inviteCode == null || inviteCode.isEmpty) {
        debugPrint('초대 코드가 없습니다: $uri');
        _handleDeepLinkError(
          '유효하지 않은 초대 링크입니다.',
          error: StateError('Missing invite code: $uri'),
        );
        return;
      }

      debugPrint('그룹 초대 링크 처리: $inviteCode');

      if (_completedInviteCodes.contains(inviteCode)) {
        _showDeepLinkMessage('이미 처리된 초대 링크입니다.');
        _safeNavigate(HomeTab.groups.routePath);
        return;
      }

      // 로그인 상태 확인
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session == null) {
        debugPrint('로그인이 필요합니다. 로그인 페이지로 이동');
        _queueInviteCode(inviteCode);
        _showDeepLinkMessage('로그인 후 자동으로 그룹에 가입합니다.');
        _safeNavigate('/auth');
        return;
      }

      await _processInviteCode(inviteCode);
    } catch (error, stackTrace) {
      debugPrint('그룹 초대 처리 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');

      _handleDeepLinkError(
        '그룹 가입에 실패했습니다. 잠시 후 다시 시도해주세요.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _handleHomeTabLink(HomeTab tab) async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      debugPrint('탭 딥링크 처리 전에 로그인이 필요합니다.');
      _showDeepLinkMessage('로그인이 필요합니다. 먼저 로그인해주세요.');
      _safeNavigate('/auth');
      return;
    }

    if (mounted) {
      _safeNavigate(tab.routePath);
    }
  }

  HomeTab? _maybeParseHomeTabUri(Uri uri) {
    if (uri.scheme.toLowerCase() != 'splitbills') {
      return null;
    }

    final candidates = <String?>[
      uri.queryParameters['tab'],
      uri.host.isEmpty ? null : uri.host,
      if (uri.pathSegments.isNotEmpty) uri.pathSegments.first,
    ];

    for (final candidate in candidates) {
      final tab = HomeTabX.maybeFromName(candidate);
      if (tab != null) {
        return tab;
      }
    }

    return null;
  }

  bool _isGroupInviteUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'splitbills') {
      if (uri.host.toLowerCase() == 'invite') {
        return true;
      }
      return uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.toLowerCase() == 'invite';
    }

    if (scheme == 'tricount') {
      final host = uri.host.toLowerCase();
      if (host == 'invite') {
        return true;
      }
      if (host == 'group') {
        return uri.pathSegments.isNotEmpty &&
            uri.pathSegments.first.toLowerCase() == 'join';
      }
      return uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.toLowerCase() == 'invite';
    }

    return false;
  }

  String? _parseInviteCode(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final queryCode = uri.queryParameters['code']?.trim();
    if (queryCode != null && queryCode.isNotEmpty) {
      return queryCode;
    }

    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList();

    if (scheme == 'splitbills') {
      // splitbills://invite/<code>
      if (uri.host.toLowerCase() == 'invite') {
        if (segments.isEmpty) {
          return null;
        }
        final candidate = segments.first.trim();
        return candidate.isNotEmpty ? candidate : null;
      }

      // splitbills://invite/<code> (경로 기반)
      if (segments.isNotEmpty && segments.first.toLowerCase() == 'invite') {
        if (segments.length < 2) {
          return null;
        }
        final candidate = segments[1].trim();
        return candidate.isNotEmpty ? candidate : null;
      }
    }

    if (scheme == 'tricount') {
      if (uri.host.toLowerCase() == 'invite') {
        if (segments.isEmpty) {
          return null;
        }
        final candidate = segments.first.trim();
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }

      if (segments.length >= 2 && segments.first.toLowerCase() == 'invite') {
        final candidate = segments[1].trim();
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }

      if (uri.host.toLowerCase() == 'group') {
        if (segments.length >= 2) {
          final candidate = segments[1].trim();
          if (candidate.isNotEmpty && candidate.toLowerCase() != 'join') {
            return candidate;
          }
        }
        if (segments.isNotEmpty) {
          final fallback = segments.last.trim();
          if (fallback.isNotEmpty && fallback.toLowerCase() != 'join') {
            return fallback;
          }
        }
      }
    }

    return null;
  }

  void _queueInviteCode(String inviteCode) {
    if (_pendingInviteCodes.contains(inviteCode)) {
      return;
    }
    _pendingInviteCodes.add(inviteCode);
  }

  Future<void> _processPendingInvites() async {
    if (_pendingInviteCodes.isEmpty) {
      return;
    }
    final queued = List<String>.from(_pendingInviteCodes);
    _pendingInviteCodes.clear();
    for (final code in queued) {
      await _processInviteCode(code);
    }
  }

  Future<void> _processInviteCode(String inviteCode) async {
    if (_completedInviteCodes.contains(inviteCode)) {
      debugPrint('이미 완료된 초대 코드: $inviteCode');
      _showDeepLinkMessage('이미 처리된 초대 링크입니다.');
      return;
    }
    if (_processingInviteCodes.contains(inviteCode)) {
      debugPrint('이미 처리 중인 초대 코드: $inviteCode');
      return;
    }

    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      _queueInviteCode(inviteCode);
      return;
    }

    _processingInviteCodes.add(inviteCode);
    try {
      final groupService = GroupService(client);
      final groupId = await groupService.joinGroupByInviteCode(inviteCode);
      debugPrint('그룹 가입 성공: $groupId');
      _completedInviteCodes.add(inviteCode);
      _showDeepLinkMessage('그룹에 가입되었습니다.');
      _safeNavigate(HomeTab.groups.routePath);
    } catch (error, stackTrace) {
      debugPrint('그룹 초대 처리 실패 ($inviteCode): $error');
      debugPrint('스택 트레이스: $stackTrace');
      final friendlyMessage = _describeInviteError(error);
      final retryable = _isRetryableInviteError(error);
      if (retryable) {
        _queueInviteCode(inviteCode);
      }
      _showInviteErrorSnackbar(
        friendlyMessage,
        inviteCode: retryable ? inviteCode : null,
      );
    } finally {
      _processingInviteCodes.remove(inviteCode);
    }
  }

  void _retryInvite(String inviteCode) {
    _pendingInviteCodes.remove(inviteCode);
    unawaited(_processInviteCode(inviteCode));
  }

  void _showInviteErrorSnackbar(
    String message, {
    String? inviteCode,
  }) {
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
                  onPressed: () => _retryInvite(inviteCode),
                ),
        ),
      );
  }

  String _describeInviteError(Object error) {
    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('유효하지') || lower.contains('invalid')) {
      return '초대 코드가 유효하지 않거나 만료되었습니다.';
    }
    if (lower.contains('만료') || lower.contains('expired')) {
      return '초대 코드가 만료되었습니다. 그룹 관리자에게 새 링크를 요청해주세요.';
    }
    if (lower.contains('권한') ||
        lower.contains('permission') ||
        lower.contains('forbidden')) {
      return '이 초대에 접근할 권한이 없습니다.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return '네트워크 연결 문제로 가입에 실패했습니다. 잠시 후 다시 시도해주세요.';
    }
    return '그룹 가입에 실패했습니다. 잠시 후 다시 시도해주세요.';
  }

  bool _isRetryableInviteError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('유효하지') ||
        lower.contains('invalid') ||
        lower.contains('만료') ||
        lower.contains('expired')) {
      return false;
    }
    return true;
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    if (!_isSupportedAuthCallback(uri)) {
      return;
    }

    final String rawUri = uri.toString();
    if (_handledAuthUris.contains(rawUri)) {
      debugPrint('이미 처리된 URI: $rawUri');
      return;
    }
    _handledAuthUris.add(rawUri);

    final client = Supabase.instance.client;

    // Provider 추출
    final provider = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : uri.queryParameters['provider'] ?? 'unknown';

    // PKCE 플로우 상태 보강
    final enhancedUri = AuthService.prepareCallbackUri(uri, provider);

    // 로그인 시작 시간 확인
    final lastSignInAttempt = AuthService.lastSignInAttemptTime;
    String? timeInfo;
    int? timeSinceSignInMs;
    if (lastSignInAttempt != null) {
      final timeSinceSignIn = DateTime.now().difference(lastSignInAttempt);
      timeSinceSignInMs = timeSinceSignIn.inMilliseconds;
      timeInfo = '로그인 시작 후 ${timeSinceSignIn.inSeconds}초';
    } else {
      timeInfo = '로그인 시작 기록 없음 (이전 플로우 콜백 가능성)';
    }

    // 로그인 시작 후 1초 이내라면 PKCE code verifier가 저장될 시간을 확보
    if (timeSinceSignInMs != null && timeSinceSignInMs < 1000) {
      final waitTime = 1000 - timeSinceSignInMs;
      debugPrint('PKCE code verifier 저장 대기: ${waitTime}ms');
      await Future.delayed(Duration(milliseconds: waitTime));
    }

    try {
      // 모든 콜백을 처리하려고 시도 (보강된 URI 사용)
      debugPrint('세션 가져오기 시도: ${enhancedUri.toString()} ($timeInfo)');
      final sessionResponse = await client.auth.getSessionFromUrl(enhancedUri);

      if (sessionResponse != null && sessionResponse.session != null) {
        debugPrint('세션 가져오기 성공');
        // 로그인 성공 시 시간, 에러, 플로우 상태 초기화
        AuthService.clearSignInAttemptTime();
        AuthService.clearAuthError();
        AuthService.clearFlowState(provider);
        await _processSuccessfulLogin(client);
        return;
      }
    } catch (error, stackTrace) {
      debugPrint('getSessionFromUrl 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');

      // flow_state_not_found 또는 Code verifier 에러인 경우 재시도
      if (error.toString().contains('flow_state_not_found') ||
          error.toString().contains('Code verifier')) {
        debugPrint('PKCE 플로우 상태가 없습니다. 재시도 중...');

        // 최대 3번까지 재시도 (PKCE code verifier가 저장될 시간 확보)
        bool retrySuccess = false;
        for (int i = 0; i < 3; i++) {
          try {
            final delayMs = 500 * (i + 1); // 500ms, 1000ms, 1500ms
            debugPrint('재시도 ${i + 1}번: ${delayMs}ms 대기 후 시도');
            await Future.delayed(Duration(milliseconds: delayMs));

            final retryResponse = await client.auth.getSessionFromUrl(
              enhancedUri,
            );
            if (retryResponse != null && retryResponse.session != null) {
              debugPrint('재시도 성공 (시도 ${i + 1}번)');
              AuthService.clearSignInAttemptTime();
              AuthService.clearAuthError();
              AuthService.clearFlowState(provider);
              await _processSuccessfulLogin(client);
              retrySuccess = true;
              break;
            }
          } catch (retryError) {
            debugPrint('재시도 ${i + 1}번 실패: $retryError');
          }
        }

        if (retrySuccess) {
          return;
        }

        // 모든 재시도 실패
        debugPrint('모든 재시도 실패. 로그인을 다시 시작해주세요.');
        AuthService.setAuthError('인증 세션이 만료되었습니다. 다시 로그인해주세요.');
      } else {
        // 다른 에러인 경우 구체적인 에러 메시지 저장
        AuthService.setAuthError('로그인 처리 중 오류가 발생했습니다: $error');
      }

      // 모든 시도가 실패한 경우 - 사용자에게 에러 표시
      debugPrint('Failed to handle auth callback for $rawUri: $error');
      _handledAuthUris.remove(rawUri);

      // 인증 페이지로 이동
      if (mounted) {
        _safeNavigate('/auth');
      }
    }
  }

  Future<void> _processSuccessfulLogin(SupabaseClient client) async {
    // 프로필 동기화 시도
    try {
      await AuthService(client).syncUserProfile();
      debugPrint('프로필 동기화 성공');
    } catch (profileError, stackTrace) {
      debugPrint('프로필 동기화 실패: $profileError');
      debugPrint('스택 트레이스: $stackTrace');
      // 프로필 동기화 실패도 에러로 처리하되, 로그인은 완료되었으므로 홈으로 이동
      AuthService.setAuthError('프로필 동기화 중 오류가 발생했습니다: $profileError');
    }

    await _processPendingInvites();

    // 성공적으로 로그인되었으므로 홈으로 이동
    if (mounted) {
      debugPrint('홈으로 이동 시도');
      _safeNavigate(HomeTab.groups.routePath);
    }
  }

  void _handleDeepLinkError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    bool navigateToSafeRoute = true,
  }) {
    if (error != null) {
      debugPrint('딥링크 처리 실패: $error');
    }
    if (stackTrace != null) {
      debugPrint('딥링크 오류 스택: $stackTrace');
    }
    _showDeepLinkMessage(message);
    if (navigateToSafeRoute) {
      _navigateToSafeEntry();
    }
  }

  void _showDeepLinkMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = _scaffoldMessengerKey.currentState;
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
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

  bool _isSupportedAuthCallback(Uri uri) {
    if (uri.scheme != 'tricount' || uri.host != 'auth') {
      return false;
    }

    final String? provider = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : uri.queryParameters['provider'];

    return provider != null &&
        const {'kakao', 'google', 'apple'}.contains(provider.toLowerCase());
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
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
