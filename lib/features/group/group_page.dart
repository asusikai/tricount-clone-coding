import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../core/utils/utils.dart';
import '../../domain/models/models.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/widgets/common/common_widgets.dart';
import 'group_edit_dialog.dart';

enum _ExpenseTab { byDate, byUser }

enum _GroupMenuAction { edit, delete }

class GroupPage extends ConsumerStatefulWidget {
  const GroupPage({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends ConsumerState<GroupPage> {
  _ExpenseTab _selectedTab = _ExpenseTab.byDate;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final expensesAsync = ref.watch(groupExpensesProvider(widget.groupId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final manageMenu = detailAsync.maybeWhen<Widget?>(
      data: (detail) {
        if (currentUserId == null || detail.ownerId != currentUserId) {
          return null;
        }
        return PopupMenuButton<_GroupMenuAction>(
          tooltip: '그룹 관리',
          icon: const Icon(Icons.more_vert),
          onSelected: (action) => _handleMenuAction(action, detail),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _GroupMenuAction.edit,
              child: Text('그룹 정보 수정'),
            ),
            PopupMenuItem(
              value: _GroupMenuAction.delete,
              child: Text('그룹 삭제'),
            ),
          ],
        );
      },
      orElse: () => null,
    );

    VoidCallback? shareAction = detailAsync.maybeWhen(
      data: (detail) => () {
        unawaited(_shareInvite(context, ref, detail));
      },
      orElse: () => null,
    );

    final title = detailAsync.maybeWhen(
      data: (detail) {
        final name = detail.name.trim();
        return name.isEmpty ? '그룹' : name;
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
          if (manageMenu != null) manageMenu,
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
                  final code = detail.inviteCode;
                  if (code.isNotEmpty) {
                    unawaited(_copyInviteCode(context, code));
                  }
                },
              ),
              const SizedBox(height: 16),
              ..._buildExpenseWidgets(
                context: context,
                expensesAsync: expensesAsync,
                membersAsync: membersAsync,
                baseCurrency: detail.baseCurrency,
                currentUserId: currentUserId,
                onRefresh: () => _refresh(ref),
              ),
              const SizedBox(height: 24),
              _GroupMembersSection(
                membersAsync: membersAsync,
                onRefresh: () => _refresh(ref),
              ),
            ],
          ),
        ),
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          error: error,
          title: '그룹 정보를 불러오지 못했습니다.',
          onRetry: () => unawaited(_refresh(ref)),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(groupDetailProvider(widget.groupId).future),
      ref.refresh(groupMembersProvider(widget.groupId).future),
      ref.refresh(groupExpensesProvider(widget.groupId).future),
    ]);
  }

  Future<void> _handleMenuAction(
    _GroupMenuAction action,
    GroupDto detail,
  ) async {
    switch (action) {
      case _GroupMenuAction.edit:
        await _handleGroupEdit(detail);
        break;
      case _GroupMenuAction.delete:
        await _handleGroupDelete(detail);
        break;
    }
  }

  Future<void> _handleGroupEdit(GroupDto detail) async {
    final didUpdate = await showGroupEditDialog(
      context,
      group: detail,
    );
    if (didUpdate == true) {
      await _refresh(ref);
      if (!mounted) {
        return;
      }
      SnackBarHelper.showSuccess(context, '그룹 정보가 수정되었습니다.');
    }
  }

  Future<void> _handleGroupDelete(GroupDto detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final name = detail.name.trim();
        return AlertDialog(
          title: const Text('그룹 삭제'),
          content: Text(
            name.isEmpty
                ? '이 그룹을 삭제하시겠어요? 삭제 후에는 되돌릴 수 없습니다.'
                : '"$name" 그룹을 삭제하시겠어요? 삭제 후에는 되돌릴 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    final controller = ref.read(groupListControllerProvider.notifier);
    final result = await controller.deleteGroup(detail.id);
    if (!mounted) {
      return;
    }

    result.fold(
      onSuccess: (_) {
        SnackBarHelper.showSuccess(context, '그룹이 삭제되었습니다.');
        Navigator.of(context).pop();
      },
      onFailure: (error) {
        SnackBarHelper.showError(
          context,
          '그룹 삭제 실패: ${error.message}',
        );
      },
    );
  }

  Future<void> _shareInvite(
    BuildContext context,
    WidgetRef ref,
    GroupDto detail,
  ) async {
    try {
      final repository = ref.read(groupsRepositoryProvider);
      final inviteLink =
          await repository.getInviteLink(widget.groupId).unwrap();
      final groupName = detail.name.trim();
      final subject = groupName.isEmpty
          ? 'splitBills 그룹 초대'
          : 'splitBills: $groupName 초대';
      await ShareHelper.shareLink(inviteLink, subject: subject);
    } catch (error, stackTrace) {
      debugPrint('초대 링크 공유 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      if (!context.mounted) {
        return;
      }
      SnackBarHelper.showError(
        context,
        '초대 링크를 공유할 수 없습니다. 다시 시도해주세요. ($error)',
      );
    }
  }

  Future<void> _copyInviteCode(BuildContext context, String inviteCode) async {
    await ClipboardHelper.copyTextWithFeedback(
      context,
      inviteCode,
      successMessage: '초대 코드가 복사되었습니다.',
    );
  }

  List<Widget> _buildExpenseWidgets({
    required BuildContext context,
    required AsyncValue<List<ExpenseDto>> expensesAsync,
    required AsyncValue<List<GroupMemberDetail>> membersAsync,
    required String baseCurrency,
    required String? currentUserId,
    required Future<void> Function() onRefresh,
  }) {
    final memberLookup = membersAsync.maybeWhen(
      data: (members) => {
        for (final detail in members) detail.member.userId: detail,
      },
      orElse: () => <String, GroupMemberDetail>{},
    );

    return expensesAsync.when(
      data: (expenses) {
        final widgets = <Widget>[
          _ExpenseOverviewCard(
            expenses: expenses,
            baseCurrency: baseCurrency,
            currentUserId: currentUserId,
          ),
          const SizedBox(height: 16),
        ];

        if (expenses.isEmpty) {
          widgets.add(
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyStateView(
                  icon: Icons.receipt_long,
                  title: '등록된 지출이 없습니다',
                  message: '지출을 추가하면 요약과 리스트가 표시됩니다.',
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          );
        } else {
          widgets.add(
            _GroupExpensesTabView(
              expenses: expenses,
              memberLookup: memberLookup,
              baseCurrency: baseCurrency,
              selectedTab: _selectedTab,
              onTabChanged: (tab) {
                setState(() => _selectedTab = tab);
              },
            ),
          );
        }
        return widgets;
      },
      loading: () => const [
        LoadingView(
          padding: EdgeInsets.symmetric(vertical: 32),
        ),
      ],
      error: (error, stackTrace) => [
        ErrorView(
          error: error,
          title: '지출 정보를 불러오지 못했습니다.',
          onRetry: () => unawaited(onRefresh()),
        ),
      ],
    );
  }
}

class _GroupSummaryCard extends StatelessWidget {
  const _GroupSummaryCard({
    required this.detail,
    required this.onCopyInviteCode,
  });

  final GroupDto detail;
  final VoidCallback onCopyInviteCode;

  @override
  Widget build(BuildContext context) {
    final baseCurrency = detail.baseCurrency;
    final inviteCode = detail.inviteCode;
    final createdAt = detail.createdAt;
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

class _ExpenseOverviewCard extends StatelessWidget {
  const _ExpenseOverviewCard({
    required this.expenses,
    required this.baseCurrency,
    required this.currentUserId,
  });

  final List<ExpenseDto> expenses;
  final String baseCurrency;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final totalSpent =
        expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

    double paidByMe = 0;
    double myShare = 0;
    if (currentUserId != null) {
      for (final expense in expenses) {
        if (expense.payerId == currentUserId) {
          paidByMe += expense.amount;
        }
        final share = _findParticipantShare(expense, currentUserId!);
        if (share != null) {
          myShare += share.amount ?? (expense.amount * share.ratio);
        }
      }
    }
    final balance = paidByMe - myShare;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('요약', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OverviewMetric(
                    label: '총 지출',
                    value: CurrencyFormatter.format(
                      totalSpent,
                      currency: baseCurrency,
                    ),
                  ),
                ),
                if (currentUserId != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewMetric(
                      label: '내 지분',
                      value: CurrencyFormatter.format(
                        myShare,
                        currency: baseCurrency,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OverviewMetric(
                      label: '내 잔액',
                      value: CurrencyFormatter.format(
                        balance,
                        currency: baseCurrency,
                      ),
                      emphasize: balance >= 0,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = emphasize ? Colors.green : textTheme.bodyLarge?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _GroupExpensesTabView extends StatelessWidget {
  const _GroupExpensesTabView({
    required this.expenses,
    required this.memberLookup,
    required this.baseCurrency,
    required this.selectedTab,
    required this.onTabChanged,
  });

  final List<ExpenseDto> expenses;
  final Map<String, GroupMemberDetail> memberLookup;
  final String baseCurrency;
  final _ExpenseTab selectedTab;
  final ValueChanged<_ExpenseTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('지출 내역', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<_ExpenseTab>(
              segments: const [
                ButtonSegment(
                  value: _ExpenseTab.byDate,
                  label: Text('날짜별'),
                  icon: Icon(Icons.calendar_today_outlined),
                ),
                ButtonSegment(
                  value: _ExpenseTab.byUser,
                  label: Text('사용자별'),
                  icon: Icon(Icons.person_outline),
                ),
              ],
              selected: <_ExpenseTab>{selectedTab},
              onSelectionChanged: (value) {
                if (value.isNotEmpty) {
                  onTabChanged(value.first);
                }
              },
            ),
            const SizedBox(height: 16),
            if (selectedTab == _ExpenseTab.byDate)
              _ExpensesByDate(
                expenses: expenses,
                memberLookup: memberLookup,
                baseCurrency: baseCurrency,
              )
            else
              _ExpensesByUser(
                expenses: expenses,
                memberLookup: memberLookup,
                baseCurrency: baseCurrency,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesByDate extends StatelessWidget {
  const _ExpensesByDate({
    required this.expenses,
    required this.memberLookup,
    required this.baseCurrency,
  });

  final List<ExpenseDto> expenses;
  final Map<String, GroupMemberDetail> memberLookup;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    final sorted = [...expenses]
      ..sort(
        (a, b) =>
            b.expenseDate.compareTo(a.expenseDate),
      );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      separatorBuilder: (context, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final expense = sorted[index];
        final description = (expense.description?.trim().isNotEmpty ?? false)
            ? expense.description!.trim()
            : '지출';
        final dateText =
            DateFormat('yyyy.MM.dd').format(expense.expenseDate.toLocal());
        final payer = _resolveUserNameFromLookup(
          expense.payerId,
          memberLookup,
        );
        final currency =
            expense.currency.isEmpty ? baseCurrency : expense.currency;
        final amountText = CurrencyFormatter.format(
          expense.amount,
          currency: currency,
        );

        return ListTile(
          title: Text(description),
          subtitle: Text('$dateText · $payer'),
          trailing: Text(
            amountText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

class _ExpensesByUser extends StatelessWidget {
  const _ExpensesByUser({
    required this.expenses,
    required this.memberLookup,
    required this.baseCurrency,
  });

  final List<ExpenseDto> expenses;
  final Map<String, GroupMemberDetail> memberLookup;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.payerId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (context, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final name = _resolveUserNameFromLookup(entry.key, memberLookup);
        final amountText = CurrencyFormatter.format(
          entry.value,
          currency: baseCurrency,
        );

        return ListTile(
          leading: CircleAvatar(
            child: Text(_userInitial(name)),
          ),
          title: Text(name),
          trailing: Text(
            amountText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}

ParticipantShare? _findParticipantShare(ExpenseDto expense, String userId) {
  for (final share in expense.participants) {
    if (share.userId == userId) {
      return share;
    }
  }
  return null;
}

String _resolveUserNameFromLookup(
  String userId,
  Map<String, GroupMemberDetail> lookup,
) {
  final detail = lookup[userId];
  if (detail == null) {
    return '사용자 $userId';
  }
  return _resolveMemberDisplayName(detail);
}

String _resolveMemberDisplayName(GroupMemberDetail detail) {
  final user = detail.user;
  final name = user?.name ?? user?.nickname;
  if (name != null && name.trim().isNotEmpty) {
    return name.trim();
  }
  final email = user?.email;
  if (email != null && email.trim().isNotEmpty) {
    return email;
  }
  return '사용자 ${detail.member.userId}';
}

String _userInitial(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  return trimmed.substring(0, 1).toUpperCase();
}

class _GroupMembersSection extends StatelessWidget {
  const _GroupMembersSection({
    required this.membersAsync,
    required this.onRefresh,
  });

  final AsyncValue<List<GroupMemberDetail>> membersAsync;
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
                  return const EmptyStateView(
                    icon: Icons.person_outline,
                    title: '멤버가 없습니다',
                    message: '초대 링크를 공유해 멤버를 추가해보세요.',
                    padding: EdgeInsets.symmetric(vertical: 24),
                  );
                }
                return Column(
                  children: members
                      .map((member) => ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(_resolveMemberDisplayName(member)),
                            subtitle: _buildMemberSubtitle(member),
                          ))
                      .toList(growable: false),
                );
              },
              loading: () => const LoadingView(
                padding: EdgeInsets.symmetric(vertical: 24),
              ),
              error: (error, stackTrace) => ErrorView(
                error: error,
                title: '멤버 정보를 불러오지 못했습니다.',
                onRetry: () => unawaited(onRefresh()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget? _buildMemberSubtitle(GroupMemberDetail detail) {
    final joinedAt = detail.member.joinedAt;
    if (joinedAt == null) {
      return null;
    }
    final joinedText = DateFormat(
      'yyyy.MM.dd HH:mm',
    ).format(joinedAt.toLocal());
    return Text('참여일: $joinedText');
  }
}
