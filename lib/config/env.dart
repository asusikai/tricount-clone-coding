class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void ensureSupabase() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Supabase 환경변수가 설정되지 않았습니다. 플러터 실행 시 '
        '--dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key> 를 지정하세요.',
      );
    }
  }
}

