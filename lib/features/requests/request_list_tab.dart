import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/utils.dart';
import '../../domain/models/models.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/widgets/common/common_widgets.dart';

class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});

  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab>
    with AutomaticKeepAliveClientMixin {
  SettlementStatus? _statusFilter;

  @override
  bool get wantKeepAlive => true;

  Future<void> reload() async {
    ref.invalidate(requestListProvider(_statusFilter));
    try {
      await ref.read(requestListProvider(_statusFilter).future);
    } catch (_) {
      // 이미 SnackBar 등으로 처리되므로 무시
    }
  }

  void _updateFilter(SettlementStatus? status) {
    if (_statusFilter == status) {
      return;
    }
    setState(() {
      _statusFilter = status;
    });
    ref.invalidate(requestListProvider(_statusFilter));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final asyncRequests = ref.watch(requestListProvider(_statusFilter));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('전체'),
                selected: _statusFilter == null,
                onSelected: (_) => _updateFilter(null),
              ),
              for (final status in SettlementStatus.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: _statusFilter == status,
                  onSelected: (_) => _updateFilter(status),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncRequests.when(
              data: (requests) =>
                  _RequestListView(requests: requests, onRefresh: reload),
              loading: () => const LoadingView(),
              error: (error, stackTrace) {
                debugPrint('요청 목록 에러: $error\n$stackTrace');
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ErrorView(
                      error: error,
                      title: '요청 목록을 불러오지 못했습니다.',
                      message: '다시 시도해주세요.',
                      onRetry: () => unawaited(reload()),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestListView extends ConsumerWidget {
  const _RequestListView({required this.requests, required this.onRefresh});

  final List<SettlementDetail> requests;
  final Future<void> Function() onRefresh;
  static const _listKey = PageStorageKey<String>('requests_list');
  static const _emptyListKey = PageStorageKey<String>('requests_list_empty');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: requests.isEmpty
          ? ListView(
              key: _emptyListKey,
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                EmptyStateView(
                  icon: Icons.request_page_outlined,
                  title: '등록된 송금 요청이 없습니다.',
                ),
              ],
            )
          : ListView.separated(
              key: _listKey,
              itemCount: requests.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final detail = requests[index];
                final settlement = detail.settlement;
                final isIncoming =
                    user != null && settlement.toUserId == user.id;
                final otherUser =
                    settlement.fromUserId == user?.id ? detail.toUser : detail.fromUser;
                final otherName = otherUser?.nickname?.trim().isNotEmpty == true
                    ? otherUser!.nickname!.trim()
                    : otherUser?.name?.trim().isNotEmpty == true
                        ? otherUser!.name!.trim()
                        : (otherUser?.email ?? '알 수 없음');
                final amountText = CurrencyFormatter.formatSimple(
                  settlement.amount,
                  currency: settlement.currency,
                );
                final groupName = detail.group?.name ?? '미확인 그룹';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isIncoming
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      isIncoming ? Icons.call_received : Icons.call_made,
                      color: isIncoming
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                  title: Text(otherName),
                  subtitle: Text('$groupName · ${settlement.status.label}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (settlement.memo != null &&
                          settlement.memo!.isNotEmpty)
                        Text(
                          settlement.memo!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    final result = await context.push<bool>(
                      '/requests/${settlement.id}',
                    );
                    if (result == true) {
                      await onRefresh();
                    }
                  },
                );
              },
            ),
    );
  }
}
