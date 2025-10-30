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
    // 앱이 종료된 상태에서 deep link로 열린 경우
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });

    // 앱이 실행 중일 때 deep link를 받는 경우
    _appLinks.uriLinkStream.listen((uri) {
      Supabase.instance.client.auth.getSessionFromUrl(uri);
    });
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
