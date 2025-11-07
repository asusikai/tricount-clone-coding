import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 클립보드 복사 헬퍼
/// 
/// 텍스트를 클립보드에 복사하고 사용자에게 피드백을 제공합니다.
class ClipboardHelper {
  ClipboardHelper._();

  /// 텍스트를 클립보드에 복사
  /// 
  /// [text] 복사할 텍스트
  /// 
  /// 반환: 복사 성공 여부
  static Future<bool> copyText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      debugPrint('클립보드 복사 실패: $e');
      return false;
    }
  }

  /// 텍스트를 클립보드에 복사하고 SnackBar로 피드백 표시
  /// 
  /// [context] BuildContext
  /// [text] 복사할 텍스트
  /// [successMessage] 성공 메시지 (기본값: '복사되었습니다.')
  /// 
  /// 반환: 복사 성공 여부
  static Future<bool> copyTextWithFeedback(
    BuildContext context,
    String text, {
    String? successMessage,
  }) async {
    final success = await copyText(text);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage ?? '복사되었습니다.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    return success;
  }
}

