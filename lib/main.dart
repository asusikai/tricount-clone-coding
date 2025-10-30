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
    _handleKakaoDeepLink(_appLinks);
    _handleGoogleDeepLink(_appLinks);
    _handleAppleDeepLink(_appLinks);
  }

  void _handleKakaoDeepLink(AppLinks appLinks) {
    _listenForProviderDeepLinks(
      appLinks: appLinks,
      validator: (uri) => _matchesProvider(
        uri,
        expectedScheme: 'tricount',
        expectedHost: 'auth',
        provider: 'kakao',
      ),
    );
  }

  void _handleGoogleDeepLink(AppLinks appLinks) {
    _listenForProviderDeepLinks(
      appLinks: appLinks,
      validator: (uri) => _matchesProvider(
        uri,
        expectedScheme: 'tricount',
        expectedHost: 'auth',
        provider: 'google',
      ),
    );
  }

  void _handleAppleDeepLink(AppLinks appLinks) {
    _listenForProviderDeepLinks(
      appLinks: appLinks,
      validator: (uri) => _matchesProvider(
        uri,
        expectedScheme: 'tricount',
        expectedHost: 'auth',
        provider: 'apple',
      ),
    );
  }

  void _listenForProviderDeepLinks({
    required AppLinks appLinks,
    required bool Function(Uri uri) validator,
  }) {
    appLinks.getInitialLink().then((uri) {
      if (uri != null && validator(uri)) {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });

    appLinks.uriLinkStream.listen((uri) {
      if (validator(uri)) {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      }
    });
  }

  bool _matchesProvider(
    Uri uri, {
    required String expectedScheme,
    required String expectedHost,
    required String provider,
  }) {
    if (uri.scheme != expectedScheme) {
      return false;
    }
    if (uri.host != expectedHost) {
      return false;
    }

    return uri.queryParameters['provider'] == provider;
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
