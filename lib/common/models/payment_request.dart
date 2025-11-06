enum PaymentRequestStatus { pending, paid, rejected, rolledBack }

extension PaymentRequestStatusX on PaymentRequestStatus {
  String get dbValue {
    switch (this) {
      case PaymentRequestStatus.pending:
        return 'pending';
      case PaymentRequestStatus.paid:
        return 'paid';
      case PaymentRequestStatus.rejected:
        return 'rejected';
      case PaymentRequestStatus.rolledBack:
        return 'rolled_back';
    }
  }

  String get label {
    switch (this) {
      case PaymentRequestStatus.pending:
        return '대기 중';
      case PaymentRequestStatus.paid:
        return '송금 완료';
      case PaymentRequestStatus.rejected:
        return '거절됨';
      case PaymentRequestStatus.rolledBack:
        return '롤백됨';
    }
  }
}

PaymentRequestStatus parsePaymentRequestStatus(String? value) {
  switch (value) {
    case 'paid':
      return PaymentRequestStatus.paid;
    case 'rejected':
      return PaymentRequestStatus.rejected;
    case 'rolled_back':
      return PaymentRequestStatus.rolledBack;
    case 'pending':
    default:
      return PaymentRequestStatus.pending;
  }
}

class PaymentRequest {
  PaymentRequest({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.memo,
    this.group,
    this.fromUser,
    this.toUser,
  });

  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final PaymentRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? memo;
  final Map<String, dynamic>? group;
  final Map<String, dynamic>? fromUser;
  final Map<String, dynamic>? toUser;

  bool isIncoming(String userId) => toUserId == userId;

  bool isOutgoing(String userId) => fromUserId == userId;

  PaymentRequest copyWith({
    PaymentRequestStatus? status,
    String? memo,
    DateTime? updatedAt,
  }) {
    return PaymentRequest(
      id: id,
      groupId: groupId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      currency: currency,
      status: status ?? this.status,
      memo: memo ?? this.memo,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      group: group,
      fromUser: fromUser,
      toUser: toUser,
    );
  }

  static PaymentRequest fromRow(
    Map<String, dynamic> row, {
    Map<String, Map<String, dynamic>>? groupLookup,
    Map<String, Map<String, dynamic>>? userLookup,
  }) {
    final groupId = row['group_id'] as String;
    final fromUserId = row['from_user'] as String;
    final toUserId = row['to_user'] as String;
    final createdAtRaw = row['created_at'];
    final updatedAtRaw = row['updated_at'];

    return PaymentRequest(
      id: row['id'] as String,
      groupId: groupId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
      currency: (row['currency'] as String?) ?? 'KRW',
      status: parsePaymentRequestStatus(row['status'] as String?),
      memo: row['memo'] as String?,
      createdAt: createdAtRaw is String
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : (createdAtRaw is DateTime ? createdAtRaw : DateTime.now()),
      updatedAt: updatedAtRaw is String
          ? DateTime.tryParse(updatedAtRaw)
          : (updatedAtRaw is DateTime ? updatedAtRaw : null),
      group: groupLookup?[groupId],
      fromUser: userLookup?[fromUserId],
      toUser: userLookup?[toUserId],
    );
  }
}
