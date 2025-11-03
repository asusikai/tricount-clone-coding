import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zzkadzldbpnprzkrucfl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6a2FkemxkYnBucHJ6a3J1Y2ZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE2MTUyNDIsImV4cCI6MjA3NzE5MTI0Mn0.rpwgRwIbPaxR2h8B3En3kFXqkr56W5UPJKkC8j9fcfM',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  void _handleDeepLinks() {
    // 앱이 종료된 상태에서 딥링크로 열린 경우
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _processAuthRedirect(uri);
    });

    // 앱이 실행 중일 때 딥링크 수신
    _appLinks.uriLinkStream.listen((uri) {
      _processAuthRedirect(uri);
    });
  }
  Future<void> _processAuthRedirect(Uri uri) async {
    debugPrint('Received URI: $uri');

    // scheme, host 일치 검사
    if (uri.scheme != 'tricount' || uri.host != 'auth') return;

    // path를 통해 provider 구분
    final path = uri.path.toLowerCase();

    if ((path == '/google' || path == '/apple' || path == '/kakao') &&
        uri.queryParameters.containsKey('code')) {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        debugPrint('✅ Auth session restored for $path');
      } catch (e) {
        debugPrint('❌ Auth redirect failed: $e');
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tricount Clone',
      theme: ThemeData.light(),
      routerConfig: appRouter,
    );
  }
}
