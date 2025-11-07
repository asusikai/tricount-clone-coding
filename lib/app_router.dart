import 'package:go_router/go_router.dart';

import 'core/constants/constants.dart';
import 'features/auth/auth_page.dart';
import 'features/group/group_create_page.dart';
import 'features/group/group_page.dart';
import 'features/home/home_page.dart';
import 'features/requests/request_page.dart';
import 'features/requests/request_register_page.dart';
import 'features/splash/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: RouteConstants.splash,
  routes: [
    GoRoute(path: '/', redirect: (_, _) => RouteConstants.splash),
    GoRoute(path: RouteConstants.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: RouteConstants.auth, builder: (_, _) => const AuthPage()),
    GoRoute(
      path: RouteConstants.home,
      builder: (_, state) => HomePage(
        initialTab: HomeTabX.fromName(state.uri.queryParameters['tab']),
      ),
    ),
    GoRoute(path: RouteConstants.groupCreate, builder: (_, _) => const GroupCreatePage()),
    GoRoute(
      path: '/groups/:id',
      builder: (_, state) {
        final rawGroupId = state.pathParameters['id'];
        if (rawGroupId == null || rawGroupId.isEmpty) {
          return const HomePage(initialTab: HomeTab.groups);
        }
        final groupId = Uri.decodeComponent(rawGroupId);
        return GroupPage(groupId: groupId);
      },
    ),

    GoRoute(
      path: RouteConstants.requestRegister,
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

    GoRoute(path: RouteConstants.authKakao, builder: (_, _) => const SplashPage()),
    GoRoute(path: RouteConstants.authGoogle, builder: (_, _) => const SplashPage()),
    GoRoute(path: RouteConstants.authApple, builder: (_, _) => const SplashPage()),
  ],
);
