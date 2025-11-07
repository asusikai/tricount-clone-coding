import 'package:flutter/material.dart';

/// SnackBar 표시 헬퍼
/// 
/// 앱 전역에서 일관된 SnackBar를 표시하기 위한 유틸리티입니다.
class SnackBarHelper {
  SnackBarHelper._();

  /// 정보 메시지 표시
  /// 
  /// [context] BuildContext
  /// [message] 표시할 메시지
  /// [duration] 표시 시간 (기본값: 2초)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }

  /// 성공 메시지 표시
  /// 
  /// [context] BuildContext
  /// [message] 표시할 메시지
  /// [duration] 표시 시간 (기본값: 2초)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 에러 메시지 표시
  /// 
  /// [context] BuildContext
  /// [message] 표시할 메시지
  /// [duration] 표시 시간 (기본값: 3초)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 액션이 있는 SnackBar 표시
  /// 
  /// [context] BuildContext
  /// [message] 표시할 메시지
  /// [actionLabel] 액션 버튼 레이블
  /// [onAction] 액션 버튼 클릭 콜백
  /// [duration] 표시 시간 (기본값: 4초)
  static void showWithAction(
    BuildContext context,
    String message,
    String actionLabel,
    VoidCallback onAction, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: SnackBarAction(
          label: actionLabel,
          onPressed: onAction,
        ),
      ),
    );
  }
}

