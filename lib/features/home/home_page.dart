import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              context.go('/auth');
            },
          ),
        ],
      ),
      body: Center(
        child: user == null
            ? const Text('로그인되지 않음')
            : Text('환영합니다, ${user.email ?? 'User'}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 그룹 생성 페이지로 이동 예정
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
