import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/auth_service.dart';
import '../../core/constants/constants.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: '확인',
              onPressed: () {},
            ),
          ),
        );
        // 에러 메시지 표시 후 초기화
        AuthService.clearAuthError();
      }
    });
  }

  Future<void> _signInWithProvider(OAuthProvider provider) async {
    // 에러 메시지 초기화
    AuthService.clearAuthError();
    
    try {
      await ref.read(authServiceProvider).signInWithProvider(provider);
      // 로그인 성공 시 콜백에서 시간이 초기화됨
    } catch (e, stackTrace) {
      debugPrint('로그인 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      // 로그인 실패 시 시간 초기화 (AuthService에서도 처리되지만 확실히 하기 위해)
      AuthService.clearSignInAttemptTime();
      if (!context.mounted || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인에 실패했습니다: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
              ElevatedButton.icon(
                onPressed: () => _signInWithProvider(OAuthProvider.google),
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _signInWithProvider(OAuthProvider.apple),
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _signInWithProvider(OAuthProvider.kakao),
                icon: const Icon(Icons.chat_bubble),
                label: const Text('Continue with Kakao'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('로그아웃 중 오류가 발생했습니다: $e'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
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
