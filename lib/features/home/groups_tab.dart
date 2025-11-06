import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/group_service.dart';

class GroupsTab extends ConsumerStatefulWidget {
  const GroupsTab({super.key});

  @override
  ConsumerState<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<GroupsTab>
    with AutomaticKeepAliveClientMixin {
  static const _listKey = PageStorageKey<String>('home_groups_list');
  static const _emptyListKey = PageStorageKey<String>('home_groups_list_empty');

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshGroups() async {
    try {
      await ref.refresh(userGroupsProvider.future);
    } catch (error, stackTrace) {
      debugPrint('그룹 새로고침 실패: $error\n$stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const Center(child: Text('로그인되지 않음'));
    }

    final asyncGroups = ref.watch(userGroupsProvider);

    return asyncGroups.when(
      data: (groups) => RefreshIndicator(
        onRefresh: _refreshGroups,
        child: groups.isEmpty ? _buildEmptyList() : _buildGroupList(groups),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        debugPrint('그룹 목록 로드 실패: $error\n$stackTrace');
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.warning_amber_rounded, size: 48, color: Colors.redAccent),
            SizedBox(height: 8),
            Center(
              child: Text(
                '그룹 목록을 불러오지 못했습니다.\n다시 시도해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupList(List<Map<String, dynamic>> groups) {
    return ListView.builder(
      key: _listKey,
      padding: const EdgeInsets.all(8),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final name = (group['name'] as String?)?.trim() ?? '';
        final avatarText = name.isEmpty ? 'G' : name.substring(0, 1).toUpperCase();
        final baseCurrency = group['base_currency'] as String? ?? 'KRW';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text(avatarText)),
            title: Text(name.isEmpty ? '이름 없음' : name),
            subtitle: Text('기본 통화: $baseCurrency'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: GroupPage로 이동
              debugPrint('그룹 선택: ${group['id']}');
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyList() {
    return ListView(
      key: _emptyListKey,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            '그룹이 없습니다',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '새 그룹을 만들어보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}
