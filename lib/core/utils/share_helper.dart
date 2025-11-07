import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// 공유 기능 헬퍼
/// 
/// 링크나 텍스트를 공유하기 위한 유틸리티입니다.
class ShareHelper {
  ShareHelper._();

  /// 링크 공유
  /// 
  /// [link] 공유할 링크 URL
  /// [subject] 공유 제목 (선택사항)
  /// 
  /// 반환: 공유 성공 여부
  static Future<bool> shareLink(
    String link, {
    String? subject,
  }) async {
    try {
      await Share.share(link, subject: subject);
      return true;
    } catch (e) {
      debugPrint('링크 공유 실패: $e');
      return false;
    }
  }

  /// 텍스트 공유
  /// 
  /// [text] 공유할 텍스트
  /// [subject] 공유 제목 (선택사항)
  /// 
  /// 반환: 공유 성공 여부
  static Future<bool> shareText(
    String text, {
    String? subject,
  }) async {
    try {
      await Share.share(text, subject: subject);
      return true;
    } catch (e) {
      debugPrint('텍스트 공유 실패: $e');
      return false;
    }
  }

  /// 링크 공유 (에러 처리 포함)
  /// 
  /// [context] BuildContext (에러 메시지 표시용)
  /// [link] 공유할 링크 URL
  /// [subject] 공유 제목 (선택사항)
  /// [errorMessage] 에러 발생 시 표시할 메시지
  /// 
  /// 반환: 공유 성공 여부
  static Future<bool> shareLinkWithErrorHandling(
    BuildContext context,
    String link, {
    String? subject,
    String? errorMessage,
  }) async {
    final success = await shareLink(link, subject: subject);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage ?? '공유에 실패했습니다. 다시 시도해주세요.',
          ),
        ),
      );
    }
    return success;
  }
}

