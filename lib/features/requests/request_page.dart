import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/models/payment_request.dart';
import '../../core/utils/utils.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/widgets/common/common_widgets.dart';

class RequestPage extends ConsumerStatefulWidget {
  const RequestPage({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends ConsumerState<RequestPage> {
  bool _isUpdating = false;

  Future<void> _updateStatus(PaymentRequestStatus status) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await ref
          .read(requestServiceProvider)
          .updateStatus(requestId: widget.requestId, status: status);
      ref.invalidate(requestDetailProvider(widget.requestId));
      if (!mounted) {
        return;
      }
      SnackBarHelper.showSuccess(context, '요청 상태가 ${status.label}으로 변경되었습니다.');
      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('요청 상태 변경 실패: $error');
      if (!mounted) {
        return;
      }
      SnackBarHelper.showError(context, '상태 변경 실패: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRequest = ref.watch(requestDetailProvider(widget.requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('송금 요청 상세')),
      body: asyncRequest.when(
        data: (request) {
          if (request == null) {
            return const EmptyStateView(
              icon: Icons.error_outline,
              title: '요청을 찾을 수 없습니다.',
              message: '삭제되었거나 접근 권한이 없는 요청입니다.',
            );
          }

          final user = Supabase.instance.client.auth.currentUser;
          final isIncoming = user != null && request.isIncoming(user.id);
          final otherUser = isIncoming ? request.fromUser : request.toUser;
          final otherName =
              (otherUser?['nickname'] as String?) ??
              (otherUser?['name'] as String?) ??
              (otherUser?['email'] as String?) ??
              '알 수 없음';
          final createdAt = request.createdAt;
          final formattedDate = DateFormatter.formatDateTime(createdAt);

          final actionButtons = <Widget>[];

          if (request.status == PaymentRequestStatus.pending && isIncoming) {
            actionButtons.addAll([
              FilledButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(PaymentRequestStatus.paid),
                icon: const Icon(Icons.check_circle),
                label: const Text('송금 완료'),
              ),
              OutlinedButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(PaymentRequestStatus.rejected),
                icon: const Icon(Icons.cancel),
                label: const Text('거절'),
              ),
            ]);
          } else if (request.status != PaymentRequestStatus.pending &&
              user != null &&
              request.isOutgoing(user.id)) {
            actionButtons.add(
              OutlinedButton.icon(
                onPressed: _isUpdating
                    ? null
                    : () => _updateStatus(PaymentRequestStatus.pending),
                icon: const Icon(Icons.refresh),
                label: const Text('대기 상태로 되돌리기'),
              ),
            );
          }

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${request.amount.toStringAsFixed(2)} ${request.currency}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('상태: ${request.status.label}'),
                        Text('그룹: ${request.group?['name'] ?? '미확인 그룹'}'),
                        Text('상대방: $otherName'),
                        Text('생성일: $formattedDate'),
                        if (request.memo != null && request.memo!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '메모: ${request.memo}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.call_made),
                  title: Text(request.fromUser?['name'] as String? ?? '요청자'),
                  subtitle: Text(request.fromUser?['email'] as String? ?? ''),
                  trailing: const Text('요청자'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.call_received),
                  title: Text(request.toUser?['name'] as String? ?? '수신자'),
                  subtitle: Text(request.toUser?['email'] as String? ?? ''),
                  trailing: const Text('수신자'),
                ),
                const SizedBox(height: 24),
                if (actionButtons.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...actionButtons.map(
                        (button) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: button,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (error, stackTrace) {
          debugPrint('요청 상세 로드 실패: $error\n$stackTrace');
          return ErrorView(
            error: error,
            title: '요청 정보를 불러오지 못했습니다.',
            onRetry: () =>
                ref.invalidate(requestDetailProvider(widget.requestId)),
          );
        },
      ),
    );
  }
}
