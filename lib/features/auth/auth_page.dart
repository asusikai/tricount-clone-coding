import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/services/auth_service.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../presentation/providers/providers.dart';
import 'presentation/widgets/oauth_buttons.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 저장된 에러 메시지 확인 및 표시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final error = AuthService.lastAuthError;
      if (error != null && mounted) {
        SnackBarHelper.showWithAction(
          context,
          error,
          '확인',
          () {},
          duration: const Duration(seconds: 4),
        );
        // 에러 메시지 표시 후 초기화
        AuthService.clearAuthError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const OAuthButtons(),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).signOut();
                    if (!mounted || !context.mounted) return;
                    context.go(RouteConstants.home);
                  } catch (e, stackTrace) {
                    debugPrint('로그아웃 실패: $e');
                    debugPrint('스택 트레이스: $stackTrace');
                    if (!mounted || !context.mounted) return;
                    SnackBarHelper.showError(context, '로그아웃 중 오류가 발생했습니다: $e');
                  }
                },
                child: const Text('Skip (Guest)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
