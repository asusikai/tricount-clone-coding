import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment {
  dev,
  prod,
  staging,
  test;

  static AppEnvironment parse(String name) {
    switch (name.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'test':
      case 'testing':
        return AppEnvironment.test;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  String? get overlayFileName {
    switch (this) {
      case AppEnvironment.dev:
        return 'assets/env/.env.dev';
      case AppEnvironment.prod:
        return 'assets/env/.env.prod';
      case AppEnvironment.staging:
        return 'assets/env/.env.staging';
      case AppEnvironment.test:
        return 'assets/env/.env.test';
    }
  }
}

class Environment {
  Environment._();

  static const _baseFileName = 'assets/env/.env';
  static bool _loaded = false;
  static AppEnvironment? _current;

  static AppEnvironment get current {
    final value = _current;
    if (value == null) {
      throw StateError('Environment.load()가 호출되지 않았습니다.');
    }
    return value;
  }

  static Future<void> load({
    String? overrideFileName,
    AppEnvironment? overrideEnvironment,
  }) async {
    if (_loaded) {
      return;
    }

    final envFlag =
        const String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    _current = overrideEnvironment ?? AppEnvironment.parse(envFlag);

    // 첫 번째 파일은 merge 없이 로드
    await _loadFile(_baseFileName, optional: false, merge: false);

    // 두 번째 파일(overlay)은 기존 값과 merge
    final overlayFile =
        overrideFileName ?? _current?.overlayFileName;
    if (overlayFile != null) {
      await _loadFile(overlayFile, optional: true, merge: true);
    }

    _validateRequired();
    _loaded = true;
  }

  static Future<void> _loadFile(
    String fileName, {
    required bool optional,
    required bool merge,
  }) async {
    try {
      if (merge) {
        // 이미 로드된 환경 변수와 merge
        await dotenv.load(
          fileName: fileName,
          mergeWith: dotenv.env,
        );
      } else {
        // 첫 번째 파일은 merge 없이 로드
        await dotenv.load(fileName: fileName);
      }
      debugPrint('환경 파일 로드 완료: $fileName');
    } catch (e) {
      // 모든 예외 타입을 잡음 (FlutterError, FileNotFoundError 등)
      if (optional) {
        debugPrint('환경 파일을 찾을 수 없어 건너뜁니다: $fileName ($e)');
        return;
      }
      throw StateError(
        '환경 파일($fileName)을 불러올 수 없습니다. 프로젝트 루트의 assets/env '
        '디렉토리에 파일이 존재하는지 확인하세요.\n원본 오류: $e',
      );
    }
  }

  static void _validateRequired() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) {
      missing.add('SUPABASE_URL');
    }
    if (supabaseAnonKey.isEmpty) {
      missing.add('SUPABASE_ANON_KEY');
    }
    if (supabaseRedirectBase.isEmpty) {
      missing.add('SUPABASE_REDIRECT_URI');
    }

    if (missing.isEmpty) {
      return;
    }

    throw StateError(
      '필수 환경 변수가 누락되었습니다: ${missing.join(', ')}',
    );
  }

  static String get supabaseUrl => _read('SUPABASE_URL');
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');
  static String get supabaseRedirectBase => _read('SUPABASE_REDIRECT_URI');

  static String buildSupabaseRedirectUri(String providerName) {
    final base = supabaseRedirectBase;
    final sanitized = providerName.trim();
    if (base.isEmpty || sanitized.isEmpty) {
      return base;
    }
    if (base.endsWith('/')) {
      return '$base$sanitized';
    }
    return '$base/$sanitized';
  }

  static String _read(String key) =>
      dotenv.env[key]?.trim() ?? '';

  static void ensureSupabase() {
    _validateRequired();
  }
}
