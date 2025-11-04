import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';
import 'common/services/auth_service.dart';
import 'common/services/group_service.dart';
import 'config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.ensureSupabase();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      ),
  );
  
  runApp(const ProviderScope(child: MyApp()));
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

  @override
  void initState() {
    super.initState();
    _listenToDeepLinks();
  }

  Future<void> _listenToDeepLinks() async {
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      unawaited(_handleDeepLink(initialUri));
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      unawaited(_handleDeepLink(uri));
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    // 인증 콜백 처리
    if (_isSupportedAuthCallback(uri)) {
      await _handleAuthCallback(uri);
      return;
    }

    // 그룹 초대 딥링크 처리
    if (uri.scheme == 'tricount' && uri.host == 'group') {
      await _handleGroupInvite(uri);
      return;
    }
  }

  Future<void> _handleGroupInvite(Uri uri) async {
    try {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'join') {
        final inviteCode = uri.queryParameters['code'];
        if (inviteCode == null || inviteCode.isEmpty) {
          debugPrint('초대 코드가 없습니다: $uri');
          return;
        }

        debugPrint('그룹 초대 링크 처리: $inviteCode');

        // 로그인 상태 확인
        final client = Supabase.instance.client;
        final session = client.auth.currentSession;
        if (session == null) {
          debugPrint('로그인이 필요합니다. 로그인 페이지로 이동');
          if (mounted) {
            _safeNavigate('/auth');
          }
          return;
        }

        // 그룹 가입 처리
        final groupService = GroupService(client);
        final groupId = await groupService.joinGroupByInviteCode(inviteCode);

        debugPrint('그룹 가입 성공: $groupId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('그룹에 가입되었습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
          _safeNavigate('/home');
        }
      }
    } catch (error, stackTrace) {
      debugPrint('그룹 초대 처리 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('그룹 가입 실패: $error'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
            
            final retryResponse = await client.auth.getSessionFromUrl(enhancedUri);
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
    
    // 성공적으로 로그인되었으므로 홈으로 이동
    if (mounted) {
      debugPrint('홈으로 이동 시도');
      _safeNavigate('/home');
    }
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
      routerConfig: appRouter,
    );
  }
}
