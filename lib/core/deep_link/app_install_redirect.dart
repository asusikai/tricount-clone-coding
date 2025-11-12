import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 앱 설치 페이지 리다이렉트 유틸리티
///
/// 앱이 설치되어 있지 않을 때 Play Store 또는 App Store로 리다이렉트합니다.
class AppInstallRedirect {
  AppInstallRedirect._();

  /// Play Store URL (Android)
  /// TODO: 실제 Play Store URL로 변경하세요
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=io.splitbills.app';

  /// App Store URL (iOS)
  /// TODO: 실제 App Store URL로 변경하세요
  static const String appStoreUrl =
      'https://apps.apple.com/app/id1234567890';

  /// 현재 플랫폼에 맞는 스토어 URL 반환
  static String getStoreUrl() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return playStoreUrl;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return appStoreUrl;
    }
    // 웹 또는 기타 플랫폼의 경우 Play Store로 기본 설정
    return playStoreUrl;
  }

  /// 스토어로 리다이렉트
  ///
  /// 앱이 설치되어 있지 않을 때 호출합니다.
  static Future<bool> redirectToStore() async {
    final url = Uri.parse(getStoreUrl());
    if (await canLaunchUrl(url)) {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// 특정 URL로 리다이렉트
  ///
  /// 웹 페이지에서 사용할 수 있는 일반적인 리다이렉트 함수입니다.
  static Future<bool> redirectToUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}

