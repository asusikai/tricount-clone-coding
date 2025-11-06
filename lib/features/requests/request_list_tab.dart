import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/models/payment_request.dart';
import '../../common/services/request_service.dart';

class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});

  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab>
    with AutomaticKeepAliveClientMixin {
  PaymentRequestStatus? _statusFilter;

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

  void _updateFilter(PaymentRequestStatus? status) {
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
              for (final status in PaymentRequestStatus.values)
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
              data: (requests) => _RequestListView(
                requests: requests,
                onRefresh: reload,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) {
                debugPrint('요청 목록 에러: $error\n$stackTrace');
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Text(
                        '요청 목록을 불러오지 못했습니다.\n다시 시도해주세요.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
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
  const _RequestListView({
    required this.requests,
    required this.onRefresh,
  });

  final List<PaymentRequest> requests;
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
                SizedBox(height: 120),
                Icon(Icons.request_page_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    '등록된 송금 요청이 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            )
          : ListView.separated(
              key: _listKey,
              itemCount: requests.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final request = requests[index];
                final isIncoming =
                    user != null && request.isIncoming(user.id);
                final otherUser = request.fromUserId == user?.id
                    ? request.toUser
                    : request.fromUser;
                final otherName = (otherUser?['nickname'] as String?) ??
                    (otherUser?['name'] as String?) ??
                    (otherUser?['email'] as String?) ??
                    '알 수 없음';
                final amountText =
                    '${request.amount.toStringAsFixed(0)} ${request.currency}';
                final groupName = request.group?['name'] as String? ?? '미확인 그룹';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isIncoming ? Colors.green.shade100 : Colors.blue.shade100,
                    child: Icon(
                      isIncoming ? Icons.call_received : Icons.call_made,
                      color:
                          isIncoming ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                  title: Text(otherName),
                  subtitle: Text('$groupName · ${request.status.label}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        amountText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (request.memo != null && request.memo!.isNotEmpty)
                        Text(
                          request.memo!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    final result = await context.push<bool>(
                      '/requests/${request.id}',
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
