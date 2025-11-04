import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  Future<void> _signInWithProvider(OAuthProvider provider) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'tricount://auth/${provider.name}',
      );
      // 로그인 후 Supabase가 리디렉션으로 앱을 다시 열면,
      // SplashPage에서 세션 상태를 감지하여 화면 이동을 처리함.
    } catch (e) {
      if (!context.mounted || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
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
                  await Supabase.instance.client.auth.signOut();
                  if (!mounted || !context.mounted) return;
                  // 게스트 로그인 시 다음 화면으로 이동 (SplashPage가 세션 확인)
                  Navigator.of(context).pushReplacementNamed('/home');
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
