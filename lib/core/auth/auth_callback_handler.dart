import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// 인증 콜백 처리 핸들러
///
/// OAuth 콜백 URI를 처리하고 세션을 생성합니다.
class AuthCallbackHandler {
  AuthCallbackHandler({
    required this.onNavigate,
    required this.onShowError,
    required this.onProcessPendingInvites,
  });

  /// 네비게이션 콜백
  final void Function(String route) onNavigate;

  /// 에러 표시 콜백
  final void Function(String message) onShowError;

  /// 대기 중인 초대 코드 처리 콜백
  final Future<void> Function() onProcessPendingInvites;

  final Set<String> _handledAuthUris = <String>{};

  /// 인증 콜백 처리
  ///
  /// [uri] OAuth 콜백 URI
  /// [client] Supabase 클라이언트
  Future<void> handle(Uri uri, SupabaseClient client) async {
    if (!isSupportedAuthCallback(uri)) {
      return;
    }

    final String rawUri = uri.toString();
    if (_handledAuthUris.contains(rawUri)) {
      debugPrint('이미 처리된 URI: $rawUri');
      return;
    }
    _handledAuthUris.add(rawUri);

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
      await client.auth.getSessionFromUrl(enhancedUri);
      debugPrint('세션 가져오기 성공');
      // 로그인 성공 시 시간, 에러, 플로우 상태 초기화
      AuthService.clearSignInAttemptTime();
      AuthService.clearAuthError();
      AuthService.clearFlowState(provider);
      await _processSuccessfulLogin(client);
      return;
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

            await client.auth.getSessionFromUrl(enhancedUri);
            debugPrint('재시도 성공 (시도 ${i + 1}번)');
            AuthService.clearSignInAttemptTime();
            AuthService.clearAuthError();
            AuthService.clearFlowState(provider);
            await _processSuccessfulLogin(client);
            retrySuccess = true;
            break;
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
      onNavigate('/auth');
    }
  }

  Future<void> _processSuccessfulLogin(SupabaseClient client) async {
    // 프로필 동기화 시도 (재시도 로직 포함)
    final session = client.auth.currentSession;
    if (session != null) {
      try {
        final repository = AuthRepositoryImpl(client);
        final success = await repository.upsertFromAuthSession(session);
        if (success) {
          debugPrint('프로필 동기화 성공');
        } else {
          debugPrint('프로필 동기화 실패 (재시도 후에도 실패)');
          // 재시도 후에도 실패한 경우 에러 메시지 설정
          AuthService.setAuthError('프로필 동기화에 실패했습니다. 나중에 다시 시도해주세요.');
        }
      } catch (profileError, stackTrace) {
        debugPrint('프로필 동기화 예외 발생: $profileError');
        debugPrint('스택 트레이스: $stackTrace');
        // 예외 발생 시에도 에러 메시지 설정
        AuthService.setAuthError('프로필 동기화 중 오류가 발생했습니다: $profileError');
      }
    }

    await onProcessPendingInvites();

    // 성공적으로 로그인되었으므로 홈으로 이동
    debugPrint('홈으로 이동 시도');
    onNavigate('/groups');
  }

  /// 지원되는 인증 콜백 URI 여부 확인
  bool isSupportedAuthCallback(Uri uri) {
    if (!_isSupportedScheme(uri.scheme) || uri.host != 'auth') {
      return false;
    }

    final String? provider = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : uri.queryParameters['provider'];

    return provider != null &&
        const {'kakao', 'google', 'apple'}.contains(provider.toLowerCase());
  }

  bool _isSupportedScheme(String scheme) {
    final normalized = scheme.toLowerCase();
    return normalized == 'splitbills' || normalized == 'tricount';
  }
}
