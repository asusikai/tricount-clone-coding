import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/group_service.dart';
import '../../common/services/request_service.dart';
import '../profile/profile_page.dart';
import '../requests/request_list_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  static const List<String> _tabTitles = ['Groups', 'Requests', 'Profile'];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groups = await ref.read(groupServiceProvider).getUserGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('그룹 목록 로드 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  FloatingActionButton? _buildFab(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () {
            context.go('/group/create');
          },
          child: const Icon(Icons.add),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () async {
            final shouldRefresh = await context.push<bool>('/requests/register');
            if (shouldRefresh == true && mounted) {
              ref.invalidate(requestListProvider);
            }
          },
          child: const Icon(Icons.note_add),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final tabs = <Widget>[
      _buildGroupsTab(user),
      const RequestsTab(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_tabTitles[_selectedIndex]),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.request_page_outlined),
            selectedIcon: Icon(Icons.request_page),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildGroupsTab(User? user) {
    if (user == null) {
      return const Center(child: Text('로그인되지 않음'));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '그룹이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새 그룹을 만들어보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  () {
                    final name = (group['name'] as String?)?.trim() ?? '';
                    return name.isEmpty
                        ? 'G'
                        : name.substring(0, 1).toUpperCase();
                  }(),
                ),
              ),
              title: Text(group['name'] as String? ?? '이름 없음'),
              subtitle: Text(
                '기본 통화: ${group['base_currency'] ?? 'KRW'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: GroupPage로 이동
                debugPrint('그룹 선택: ${group['id']}');
              },
            ),
          );
        },
      ),
    );
  }
}
