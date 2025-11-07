import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../common/services/group_service.dart';
import '../../presentation/widgets/common/common_widgets.dart';

class GroupPage extends ConsumerWidget {
  const GroupPage({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    VoidCallback? shareAction = detailAsync.maybeWhen(
      data: (detail) => () {
        unawaited(_shareInvite(context, ref, detail));
      },
      orElse: () => null,
    );

    final title = detailAsync.maybeWhen(
      data: (detail) {
        final name = (detail['name'] as String?)?.trim();
        return (name == null || name.isEmpty) ? '그룹' : name;
      },
      orElse: () => '그룹',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: '초대 링크 공유',
            onPressed: shareAction,
            icon: const Icon(Icons.ios_share),
          ),
        ],
      ),
      body: detailAsync.when(
        data: (detail) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _GroupSummaryCard(
                detail: detail,
                onCopyInviteCode: () {
                  final code = (detail['invite_code'] as String?) ?? '';
                  if (code.isNotEmpty) {
                    unawaited(_copyInviteCode(context, code));
                  }
                },
              ),
              const SizedBox(height: 24),
              _GroupMembersSection(
                membersAsync: membersAsync,
                onRefresh: () => _refresh(ref),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorView(
          error: error,
          onRetry: () => unawaited(_refresh(ref)),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(groupDetailProvider(groupId).future),
      ref.refresh(groupMembersProvider(groupId).future),
    ]);
  }

  Future<void> _shareInvite(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> detail,
  ) async {
    try {
      final groupService = ref.read(groupServiceProvider);
      final inviteLink = await groupService.getInviteLink(groupId);
      final groupName = (detail['name'] as String?)?.trim() ?? '';
      final subject = groupName.isEmpty
          ? 'splitBills 그룹 초대'
          : 'splitBills: $groupName 초대';
      await Share.share(inviteLink, subject: subject);
    } catch (error, stackTrace) {
      debugPrint('초대 링크 공유 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초대 링크를 공유할 수 없습니다. 다시 시도해주세요. ($error)')),
      );
    }
  }

  Future<void> _copyInviteCode(BuildContext context, String inviteCode) async {
    await Clipboard.setData(ClipboardData(text: inviteCode));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('초대 코드가 복사되었습니다.')));
  }
}

class _GroupSummaryCard extends StatelessWidget {
  const _GroupSummaryCard({
    required this.detail,
    required this.onCopyInviteCode,
  });

  final Map<String, dynamic> detail;
  final VoidCallback onCopyInviteCode;

  @override
  Widget build(BuildContext context) {
    final baseCurrency = detail['base_currency'] as String? ?? 'KRW';
    final inviteCode = (detail['invite_code'] as String?) ?? '';
    final createdAtRaw = detail['created_at'] as String?;
    final createdAt = createdAtRaw == null
        ? null
        : DateTime.tryParse(createdAtRaw);
    final createdText = createdAt == null
        ? null
        : DateFormat('yyyy.MM.dd HH:mm').format(createdAt.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('그룹 정보', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.payments_outlined,
              label: '기본 통화',
              value: baseCurrency,
            ),
            if (createdText != null) ...[
              const SizedBox(height: 12),
              InfoRow(
                icon: Icons.calendar_month_outlined,
                label: '생성일',
                value: createdText,
              ),
            ],
            if (inviteCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InfoRow(
                      icon: Icons.qr_code_2_outlined,
                      label: '초대 코드',
                      value: inviteCode,
                    ),
                  ),
                  IconButton(
                    tooltip: '초대 코드 복사',
                    onPressed: onCopyInviteCode,
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupMembersSection extends StatelessWidget {
  const _GroupMembersSection({
    required this.membersAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<Map<String, dynamic>>> membersAsync;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('그룹 멤버', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  tooltip: '새로고침',
                  onPressed: () {
                    unawaited(onRefresh());
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Text(
                    '멤버가 없습니다. 초대 링크를 공유해 멤버를 추가해보세요.',
                    style: TextStyle(color: Colors.grey),
                  );
                }
                return Column(
                  children: members
                      .map(
                        (member) => ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(_resolveMemberName(member)),
                          subtitle: _buildMemberSubtitle(member),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '멤버 정보를 불러오지 못했습니다.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _resolveMemberName(Map<String, dynamic> member) {
    final name = (member['name'] ?? member['nickname']) as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    final email = member['email'] as String?;
    if (email != null && email.trim().isNotEmpty) {
      return email;
    }
    final userId = member['user_id']?.toString();
    return userId == null ? '알 수 없는 사용자' : '사용자 $userId';
  }

  static Widget? _buildMemberSubtitle(Map<String, dynamic> member) {
    final joinedRaw = member['joined_at'] as String?;
    if (joinedRaw == null) {
      return null;
    }
    final joinedAt = DateTime.tryParse(joinedRaw);
    if (joinedAt == null) {
      return null;
    }
    final joinedText = DateFormat(
      'yyyy.MM.dd HH:mm',
    ).format(joinedAt.toLocal());
    return Text('참여일: $joinedText');
  }
}
