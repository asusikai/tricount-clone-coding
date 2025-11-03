import 'dart:async';

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
  final AppLinks _appLinks = AppLinks();
  final Set<String> _handledAuthUris = <String>{};
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenToDeepLinks();
  }

  Future<void> _listenToDeepLinks() async {
    final Uri? initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      unawaited(_handleAuthCallback(initialUri));
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      unawaited(_handleAuthCallback(uri));
    });
  }
  Future<void> _processAuthRedirect(Uri uri) async {
    debugPrint('Received URI: $uri');
  }

  Future<void> _handleAuthCallback(Uri uri) async {
    if (!_isSupportedAuthCallback(uri)) {
      return;
    }

    final String rawUri = uri.toString();
    if (_handledAuthUris.contains(rawUri)) {
      return;
    }
    _handledAuthUris.add(rawUri);

    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (error) {
      debugPrint('Failed to handle auth callback for $rawUri: $error');
      _handledAuthUris.remove(rawUri);
    }
  }

  bool _isSupportedAuthCallback(Uri uri) {
    if (uri.scheme != 'tricount' || uri.host != 'auth') {
      return false;
    }

    final String? provider = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : uri.queryParameters['provider'];

    return provider != null &&
        const {'kakao', 'google', 'apple'}.contains(provider.toLowerCase());
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
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
