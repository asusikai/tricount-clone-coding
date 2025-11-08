import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../common/services/auth_service.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../../presentation/providers/providers.dart';

/// OAuth 로그인 버튼 위젯
///
/// Google, Apple, Kakao OAuth 로그인 버튼을 제공합니다.
class OAuthButtons extends ConsumerWidget {
  const OAuthButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GoogleButton(
          onSignIn: () => _handleSignIn(context, ref, OAuthProvider.google),
        ),
        const SizedBox(height: 12),
        if (Platform.isIOS)
          _AppleButton(
            onSignIn: () => _handleSignIn(context, ref, OAuthProvider.apple),
          ),
        const SizedBox(height: 12),
        _KakaoButton(
          onSignIn: () => _handleSignIn(context, ref, OAuthProvider.kakao),
        ),
      ],
    );
  }

  Future<void> _handleSignIn(
    BuildContext context,
    WidgetRef ref,
    OAuthProvider provider,
  ) async {
    // 에러 메시지 초기화
    AuthService.clearAuthError();

    try {
      await ref.read(authServiceProvider).signInWithProvider(provider);
      // 로그인 성공 시 콜백에서 자동으로 홈으로 이동됨
      // (onAuthStateChange에서 처리)
    } catch (e, stackTrace) {
      // 로그인 실패 시 시간 초기화
      AuthService.clearSignInAttemptTime();
      if (!context.mounted) return;

      // AppError로 매핑하여 처리
      final appError = ErrorMapper.mapAndLog(
        e,
        stackTrace: stackTrace,
        context: 'OAuth 로그인 실패',
      );

      // AppError 타입에 따라 적절한 UI 표시
      switch (appError) {
        case CancelledError():
          AppSnackbar.showCancelled(context);
        case NetworkError():
          AppSnackbar.showErrorWithRetry(
            context,
            appError,
            () => _handleSignIn(context, ref, provider),
          );
        case AuthError():
        case ConfigError():
        case PermissionError():
        case NotFoundError():
        case ValidationError():
        case UnknownError():
          AppSnackbar.showErrorWithRetry(
            context,
            appError,
            () => _handleSignIn(context, ref, provider),
          );
      }
    }
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onSignIn,
      icon: const Icon(Icons.login),
      label: const Text('Continue with Google'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}

class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onSignIn,
      icon: const Icon(Icons.apple),
      label: const Text('Continue with Apple'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}

class _KakaoButton extends StatelessWidget {
  const _KakaoButton({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onSignIn,
      icon: const Icon(Icons.chat_bubble),
      label: const Text('Continue with Kakao'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
