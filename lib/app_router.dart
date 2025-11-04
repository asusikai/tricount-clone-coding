import 'package:go_router/go_router.dart';

import 'features/auth/auth_page.dart';
import 'features/home/home_page.dart';
import 'features/splash/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/splash'),
    GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
    GoRoute(path: '/auth', builder: (_, _) => const AuthPage()),
    GoRoute(path: '/home', builder: (_, _) => const HomePage()),

    GoRoute(path: '/auth/kakao', builder: (_, _) => const SplashPage()),
    GoRoute(path: '/auth/google', builder: (_, _) => const SplashPage()),
    GoRoute(path: '/auth/apple', builder: (_, _) => const SplashPage()),
  ],
);
