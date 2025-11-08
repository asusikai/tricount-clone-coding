import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common/services/auth_service.dart';
import '../../presentation/providers/providers.dart';

/// 인증 상태 관리 유틸리티
///
/// 로그아웃/세션 만료 시 앱 상태를 초기화합니다.
class AuthStateManager {
  AuthStateManager._();

  /// 로그아웃 시 앱 상태 초기화
  ///
  /// [ref] WidgetRef (Riverpod 상태 초기화용)
  ///
  /// Riverpod Provider 상태를 초기화하고 인증 관련 캐시를 정리합니다.
  static void clearAppState(WidgetRef? ref) {
    debugPrint('앱 상태 초기화 시작');

    // 인증 관련 상태 초기화
    AuthService.clearAuthError();
    AuthService.clearSignInAttemptTime();

    // OAuth 플로우 상태 초기화 (모든 프로바이더)
    AuthService.clearFlowState('google');
    AuthService.clearFlowState('apple');
    AuthService.clearFlowState('kakao');

    // Riverpod Provider 상태 초기화 (ref가 제공된 경우)
    if (ref != null) {
      try {
        // 사용자 관련 Provider 초기화
        ref.invalidate(authServiceProvider);
        // 다른 사용자 데이터 Provider들도 초기화
        // (실제 Provider 이름에 맞게 수정 필요)
        debugPrint('Riverpod Provider 상태 초기화 완료');
      } catch (e) {
        debugPrint('Provider 상태 초기화 중 오류: $e');
      }
    }

    debugPrint('앱 상태 초기화 완료');
  }

  /// 세션 만료 시 상태 초기화
  ///
  /// [ref] WidgetRef (Riverpod 상태 초기화용)
  ///
  /// 세션 만료로 인한 로그아웃 시 호출됩니다.
  static void clearStateOnSessionExpiry(WidgetRef? ref) {
    debugPrint('세션 만료로 인한 상태 초기화');
    clearAppState(ref);
  }

  /// 사용자 삭제 시 상태 초기화
  ///
  /// [ref] WidgetRef (Riverpod 상태 초기화용)
  ///
  /// 사용자 계정이 삭제되었을 때 호출됩니다.
  static void clearStateOnUserDeleted(WidgetRef? ref) {
    debugPrint('사용자 삭제로 인한 상태 초기화');
    clearAppState(ref);
  }
}

