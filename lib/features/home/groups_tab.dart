import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/group_service.dart';
import '../../presentation/widgets/common/common_widgets.dart';

class GroupsTab extends ConsumerStatefulWidget {
  const GroupsTab({super.key});

  @override
  ConsumerState<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<GroupsTab>
    with AutomaticKeepAliveClientMixin {
  static const _listKey = PageStorageKey<String>('home_groups_list');
  static const _emptyListKey = PageStorageKey<String>('home_groups_list_empty');
  String? _sharingGroupId;

  @override
  bool get wantKeepAlive => true;

  Future<void> _refreshGroups() async {
    try {
      final _ = await ref.refresh(userGroupsProvider.future);
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
        child: groups.isEmpty
            ? ListView(
                key: _emptyListKey,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const EmptyStateView(
                    icon: Icons.group_outlined,
                    title: '그룹이 없습니다',
                    message: '새 그룹을 만들어보세요',
                  ),
                ],
              )
            : _buildGroupList(groups),
      ),
      loading: () => const LoadingView(),
      error: (error, stackTrace) {
        debugPrint('그룹 목록 로드 실패: $error\n$stackTrace');
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            ErrorView(
              error: error,
              title: '그룹 목록을 불러오지 못했습니다.',
              message: '다시 시도해주세요.',
              onRetry: () => unawaited(_refreshGroups()),
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
        final avatarText = name.isEmpty
            ? 'G'
            : name.substring(0, 1).toUpperCase();
        final baseCurrency = group['base_currency'] as String? ?? 'KRW';
        final groupId = (group['id'] ?? '').toString();
        final isSharing = _sharingGroupId == groupId;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text(avatarText)),
            title: Text(name.isEmpty ? '이름 없음' : name),
            subtitle: Text('기본 통화: $baseCurrency'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: '초대 링크 공유',
                  icon: isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  onPressed: _sharingGroupId == null
                      ? () => _shareGroupInvite(groupId, name)
                      : null,
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: groupId.isEmpty
                ? null
                : () {
                    context.go('/groups/$groupId');
                  },
          ),
        );
      },
    );
  }

  Future<void> _shareGroupInvite(String groupId, String groupName) async {
    setState(() {
      _sharingGroupId = groupId;
    });
    try {
      final groupService = ref.read(groupServiceProvider);
      final inviteLink = await groupService.getInviteLink(groupId);
      final shareSubject = groupName.isEmpty
          ? 'splitBills 그룹 초대'
          : 'splitBills: $groupName 초대';
      await Share.share(inviteLink, subject: shareSubject);
    } catch (error, stackTrace) {
      debugPrint('초대 링크 공유 실패: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('초대 링크 공유에 실패했습니다. 다시 시도해주세요. ($error)')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (_sharingGroupId == groupId) {
            _sharingGroupId = null;
          }
        });
      }
    }
  }
}
