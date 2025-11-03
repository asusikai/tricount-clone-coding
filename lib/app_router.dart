import 'package:go_router/go_router.dart';

import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';
import 'features/splash/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/splash'),
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),

    GoRoute(path: '/auth/kakao', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth/google', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth/apple', builder: (_, __) => const SplashPage()),
  ],
);
