import 'package:flutter/material.dart';

import '../error/app_error.dart';
import '../utils/snackbar_helper.dart';

/// OAuth 관련 표준화된 SnackBar 메시지
///
/// OAuth 오류/취소 시 일관된 메시지를 제공합니다.
class AppSnackbar {
  AppSnackbar._();

  /// 네트워크 오류 메시지 표시
  static void showNetworkError(BuildContext context) {
    SnackBarHelper.showError(
      context,
      '네트워크 연결을 확인해주세요.',
      duration: const Duration(seconds: 4),
    );
  }

  /// OAuth 취소 메시지 표시
  static void showCancelled(BuildContext context) {
    SnackBarHelper.showInfo(
      context,
      '로그인이 취소되었습니다.',
      duration: const Duration(seconds: 2),
    );
  }

  /// 미지원 플랫폼 메시지 표시
  ///
  /// [platform] 플랫폼 이름 (예: 'Apple')
  static void showUnsupportedPlatform(BuildContext context, String platform) {
    SnackBarHelper.showError(
      context,
      '$platform 로그인은 현재 플랫폼에서 지원되지 않습니다.',
      duration: const Duration(seconds: 3),
    );
  }

  /// AppError를 표시
  ///
  /// [error] AppError 인스턴스
  static void showError(BuildContext context, AppError error) {
    switch (error) {
      case NetworkError():
        showNetworkError(context);
      case CancelledError():
        showCancelled(context);
      case AuthError():
        SnackBarHelper.showError(
          context,
          error.message,
          duration: const Duration(seconds: 4),
        );
      case ConfigError():
        showConfigError(context, error.message);
      case PermissionError():
        SnackBarHelper.showError(
          context,
          error.message,
          duration: const Duration(seconds: 3),
        );
      case NotFoundError():
      case ValidationError():
      case UnknownError():
        SnackBarHelper.showError(
          context,
          error.message,
          duration: const Duration(seconds: 4),
        );
    }
  }

  /// AppError를 표시 (재시도 액션 포함)
  ///
  /// [error] AppError 인스턴스
  /// [onRetry] 재시도 콜백
  static void showErrorWithRetry(
    BuildContext context,
    AppError error,
    VoidCallback onRetry,
  ) {
    switch (error) {
      case NetworkError():
        SnackBarHelper.showWithAction(
          context,
          error.message,
          '재시도',
          onRetry,
          duration: const Duration(seconds: 5),
        );
      case CancelledError():
        showCancelled(context);
      case AuthError():
        SnackBarHelper.showWithAction(
          context,
          error.message,
          '재시도',
          onRetry,
          duration: const Duration(seconds: 5),
        );
      case ConfigError():
      case PermissionError():
      case NotFoundError():
      case ValidationError():
      case UnknownError():
        SnackBarHelper.showWithAction(
          context,
          error.message,
          '재시도',
          onRetry,
          duration: const Duration(seconds: 5),
        );
    }
  }

  /// OAuth 일반 오류 메시지 표시
  ///
  /// [error] 오류 메시지 또는 예외
  /// @deprecated Use showError with AppError instead
  static void showOAuthError(BuildContext context, Object error) {
    final message = _extractErrorMessage(error);
    SnackBarHelper.showError(
      context,
      '로그인 중 오류가 발생했습니다: $message',
      duration: const Duration(seconds: 4),
    );
  }

  /// OAuth 오류 메시지 표시 (재시도 액션 포함)
  ///
  /// [error] 오류 메시지 또는 예외
  /// [onRetry] 재시도 콜백
  /// @deprecated Use showErrorWithRetry with AppError instead
  static void showOAuthErrorWithRetry(
    BuildContext context,
    Object error,
    VoidCallback onRetry,
  ) {
    final message = _extractErrorMessage(error);
    SnackBarHelper.showWithAction(
      context,
      '로그인 중 오류가 발생했습니다: $message',
      '재시도',
      onRetry,
      duration: const Duration(seconds: 5),
    );
  }

  /// 인증 세션 만료 메시지 표시
  static void showSessionExpired(BuildContext context) {
    SnackBarHelper.showError(
      context,
      '인증 세션이 만료되었습니다. 다시 로그인해주세요.',
      duration: const Duration(seconds: 4),
    );
  }

  /// 인증 설정 오류 메시지 표시
  ///
  /// 환경 변수나 URL 스킴 설정 오류 시 사용
  static void showConfigError(BuildContext context, String details) {
    SnackBarHelper.showError(
      context,
      '인증 설정 오류: $details',
      duration: const Duration(seconds: 5),
    );
  }

  /// 오류 메시지 추출
  ///
  /// 예외 객체에서 사용자에게 표시할 메시지를 추출합니다.
  static String _extractErrorMessage(Object error) {
    final errorString = error.toString();

    // 일반적인 오류 패턴 매칭
    if (errorString.contains('network') ||
        errorString.contains('Network') ||
        errorString.contains('connection')) {
      return '네트워크 연결 오류';
    }

    if (errorString.contains('cancelled') ||
        errorString.contains('canceled') ||
        errorString.contains('취소')) {
      return '사용자 취소';
    }

    if (errorString.contains('timeout') || errorString.contains('타임아웃')) {
      return '요청 시간 초과';
    }

    if (errorString.contains('unauthorized') || errorString.contains('인증')) {
      return '인증 실패';
    }

    if (errorString.contains('not found') || errorString.contains('찾을 수 없음')) {
      return '리소스를 찾을 수 없습니다';
    }

    // 기본값: 원본 메시지의 일부만 표시 (너무 길면 잘라냄)
    if (errorString.length > 100) {
      return '${errorString.substring(0, 100)}...';
    }

    return errorString;
  }
}
