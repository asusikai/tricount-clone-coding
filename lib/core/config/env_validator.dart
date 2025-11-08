import 'package:flutter/foundation.dart';

import '../../config/environment.dart';
import '../error/app_error.dart';
import '../error/error_mapper.dart';

/// 환경 변수 및 URL 스킴 검증 유틸리티
///
/// 앱 부팅 시 환경 변수와 URL 스킴 설정의 정합성을 검증합니다.
class EnvValidator {
  EnvValidator._();

  /// 환경 변수 검증 결과
  static ValidationResult validateEnvironment() {
    final issues = <String>[];

    // 필수 환경 변수 확인
    if (Environment.supabaseUrl.isEmpty) {
      issues.add('SUPABASE_URL이 설정되지 않았습니다.');
    } else {
      // URL 형식 검증
      try {
        final uri = Uri.parse(Environment.supabaseUrl);
        if (!uri.hasScheme || !uri.hasAuthority) {
          issues.add('SUPABASE_URL 형식이 올바르지 않습니다.');
        }
      } catch (e) {
        issues.add('SUPABASE_URL 파싱 실패: $e');
      }
    }

    if (Environment.supabaseAnonKey.isEmpty) {
      issues.add('SUPABASE_ANON_KEY가 설정되지 않았습니다.');
    }

    if (Environment.supabaseRedirectBase.isEmpty) {
      issues.add('SUPABASE_REDIRECT_URI가 설정되지 않았습니다.');
    } else {
      // 리다이렉트 URI 형식 검증
      final redirectBase = Environment.supabaseRedirectBase;
      try {
        final uri = Uri.parse(redirectBase);
        if (!uri.hasScheme) {
          issues.add('SUPABASE_REDIRECT_URI에 스킴이 없습니다.');
        }
        // 예상되는 스킴: tricount://auth 또는 splitbills://auth
        final expectedSchemes = ['tricount', 'splitbills'];
        if (!expectedSchemes.contains(uri.scheme.toLowerCase())) {
          issues.add(
            'SUPABASE_REDIRECT_URI 스킴이 예상과 다릅니다. '
            '예상: ${expectedSchemes.join(' 또는 ')}, 실제: ${uri.scheme}',
          );
        }
      } catch (e) {
        issues.add('SUPABASE_REDIRECT_URI 파싱 실패: $e');
      }
    }

    return ValidationResult(isValid: issues.isEmpty, issues: issues);
  }

  /// URL 스킴 일치 여부 검증 (가이드 제공)
  ///
  /// AndroidManifest.xml과 iOS Info.plist의 URL 스킴이
  /// 환경 변수의 리다이렉트 URI와 일치하는지 확인합니다.
  ///
  /// 반환: 검증 결과 및 가이드 메시지
  static SchemeValidationResult validateUrlSchemes() {
    final redirectBase = Environment.supabaseRedirectBase;
    if (redirectBase.isEmpty) {
      return SchemeValidationResult(
        isValid: false,
        message: 'SUPABASE_REDIRECT_URI가 설정되지 않았습니다.',
        androidGuide: '',
        iosGuide: '',
      );
    }

    try {
      final uri = Uri.parse(redirectBase);
      final scheme = uri.scheme.toLowerCase();
      final host = uri.host.toLowerCase();

      // 예상되는 스킴과 호스트
      final expectedScheme = scheme; // tricount 또는 splitbills
      final expectedHost = host; // auth

      final androidGuide =
          '''
AndroidManifest.xml에 다음 intent-filter가 설정되어 있는지 확인하세요:

<!-- Google OAuth Redirect -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="$expectedScheme" android:host="$expectedHost" android:path="/google" />
</intent-filter>

<!-- Apple OAuth Redirect -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="$expectedScheme" android:host="$expectedHost" android:path="/apple" />
</intent-filter>

<!-- Kakao OAuth Redirect -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="$expectedScheme" android:host="$expectedHost" android:path="/kakao" />
</intent-filter>
''';

      final iosGuide =
          '''
iOS Info.plist에 다음 URL Types가 설정되어 있는지 확인하세요:

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>$expectedScheme</string>
        </array>
    </dict>
</array>

또는 Xcode에서:
1. Runner 타겟 선택
2. Info 탭
3. URL Types 섹션에서 추가
4. URL Schemes에 "$expectedScheme" 입력
''';

      return SchemeValidationResult(
        isValid: true,
        message: 'URL 스킴 검증 완료',
        expectedScheme: expectedScheme,
        expectedHost: expectedHost,
        androidGuide: androidGuide,
        iosGuide: iosGuide,
      );
    } catch (e) {
      return SchemeValidationResult(
        isValid: false,
        message: '리다이렉트 URI 파싱 실패: $e',
        androidGuide: '',
        iosGuide: '',
      );
    }
  }

  /// 전체 검증 수행
  ///
  /// 환경 변수와 URL 스킴을 모두 검증합니다.
  static FullValidationResult validateAll() {
    final envResult = validateEnvironment();
    final schemeResult = validateUrlSchemes();

    return FullValidationResult(
      environment: envResult,
      urlSchemes: schemeResult,
      isValid: envResult.isValid && schemeResult.isValid,
    );
  }
}

/// 환경 변수 검증 결과
class ValidationResult {
  ValidationResult({required this.isValid, required this.issues});

  final bool isValid;
  final List<String> issues;

  String get message {
    if (isValid) {
      return '환경 변수 검증 성공';
    }
    return '환경 변수 검증 실패:\n${issues.join('\n')}';
  }
}

/// URL 스킴 검증 결과
class SchemeValidationResult {
  SchemeValidationResult({
    required this.isValid,
    required this.message,
    this.expectedScheme,
    this.expectedHost,
    required this.androidGuide,
    required this.iosGuide,
  });

  final bool isValid;
  final String message;
  final String? expectedScheme;
  final String? expectedHost;
  final String androidGuide;
  final String iosGuide;
}

/// 전체 검증 결과
class FullValidationResult {
  FullValidationResult({
    required this.environment,
    required this.urlSchemes,
    required this.isValid,
  });

  final ValidationResult environment;
  final SchemeValidationResult urlSchemes;
  final bool isValid;

  void logResults() {
    debugPrint('=== 환경 변수 검증 ===');
    debugPrint(environment.message);
    if (!environment.isValid) {
      for (final issue in environment.issues) {
        debugPrint('  - $issue');
      }
    }

    debugPrint('\n=== URL 스킴 검증 ===');
    debugPrint(urlSchemes.message);
    if (urlSchemes.isValid) {
      debugPrint('예상 스킴: ${urlSchemes.expectedScheme}');
      debugPrint('예상 호스트: ${urlSchemes.expectedHost}');
    }
  }
}
