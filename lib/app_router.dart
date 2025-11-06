import 'package:go_router/go_router.dart';

import 'features/auth/auth_page.dart';
import 'features/group/group_create_page.dart';
import 'features/home/home_page.dart';
import 'features/requests/request_page.dart';
import 'features/requests/request_register_page.dart';
import 'features/splash/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/', redirect: (_, __) => '/splash'),
    GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
    GoRoute(path: '/home', builder: (_, __) => const HomePage()),
    GoRoute(
      path: '/group/create',
      builder: (_, __) => const GroupCreatePage(),
    ),

    GoRoute(
      path: '/requests/register',
      builder: (_, __) => const RequestRegisterPage(),
    ),
    GoRoute(
      path: '/requests/:id',
      builder: (_, state) {
        final requestId = state.pathParameters['id'];
        if (requestId == null) {
          return const HomePage();
        }
        return RequestPage(requestId: requestId);
      },
    ),

    GoRoute(path: '/auth/kakao', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth/google', builder: (_, __) => const SplashPage()),
    GoRoute(path: '/auth/apple', builder: (_, __) => const SplashPage()),
  ],
);
