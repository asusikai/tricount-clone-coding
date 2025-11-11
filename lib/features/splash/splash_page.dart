import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/constants.dart';
import '../../presentation/providers/providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1)); // 로딩 연출

    // async gap 이후에 반드시 mounted 확인
    if (!mounted) return;

    final client = Supabase.instance.client;
    final session = client.auth.currentSession;

    if (session == null) {
      debugPrint('SplashPage: 세션이 없습니다. 인증 페이지로 이동');
      if (!mounted) return;
      context.go(RouteConstants.auth);
    } else {
      // 세션 만료 확인
      final expiresAt = session.expiresAt;
      if (expiresAt != null) {
        final expiresDateTime = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        final now = DateTime.now();
        final isExpired = expiresDateTime.isBefore(now);
        debugPrint('SplashPage: 세션 만료 시간 확인 - expiresAt=$expiresDateTime, 현재=$now, 만료됨=$isExpired');
        
        if (isExpired) {
          debugPrint('SplashPage: 세션이 만료되었습니다. 세션 갱신 시도');
          try {
            // 만료된 세션 갱신 시도
            await client.auth.refreshSession();
            debugPrint('SplashPage: 세션 갱신 성공');
          } catch (error) {
            debugPrint('SplashPage: 세션 갱신 실패: $error');
            // 갱신 실패 시 로그아웃 처리
            if (!mounted) return;
            context.go(RouteConstants.auth);
            return;
          }
        }
      }
      
      try {
        await ref.read(authServiceProvider).syncUserProfile();
      } catch (error) {
        debugPrint('사용자 프로필 동기화 실패: $error');
      }
      if (!mounted) return;
      context.go(RouteConstants.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
