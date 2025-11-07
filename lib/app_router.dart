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
    GoRoute(path: '/', redirect: (_, _) => '/splash'),
    GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
    GoRoute(path: '/auth', builder: (_, _) => const AuthPage()),
    GoRoute(
      path: '/home',
      builder: (_, state) => HomePage(
        initialTab: HomeTabX.fromName(state.uri.queryParameters['tab']),
      ),
    ),
    GoRoute(path: '/group/create', builder: (_, _) => const GroupCreatePage()),

    GoRoute(
      path: '/requests/register',
      builder: (_, _) => const RequestRegisterPage(),
    ),
    GoRoute(
      path: '/requests/:id',
      builder: (_, state) {
        final requestId = state.pathParameters['id'];
        if (requestId == null) {
          return const HomePage(initialTab: HomeTab.requests);
        }
        return RequestPage(requestId: requestId);
      },
    ),

    GoRoute(path: '/auth/kakao', builder: (_, _) => const SplashPage()),
    GoRoute(path: '/auth/google', builder: (_, _) => const SplashPage()),
    GoRoute(path: '/auth/apple', builder: (_, _) => const SplashPage()),
  ],
);
