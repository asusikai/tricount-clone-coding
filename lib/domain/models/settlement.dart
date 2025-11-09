enum SettlementStatus {
  pending,
  paid,
  rejected,
  rolledBack,
}

extension SettlementStatusX on SettlementStatus {
  String get label {
    switch (this) {
      case SettlementStatus.pending:
        return '대기';
      case SettlementStatus.paid:
        return '완료';
      case SettlementStatus.rejected:
        return '거절';
      case SettlementStatus.rolledBack:
        return '롤백';
    }
  }

  String get dbValue {
    switch (this) {
      case SettlementStatus.pending:
        return 'pending';
      case SettlementStatus.paid:
        return 'paid';
      case SettlementStatus.rejected:
        return 'rejected';
      case SettlementStatus.rolledBack:
        return 'rolled_back';
    }
  }

  static SettlementStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
        return SettlementStatus.paid;
      case 'rejected':
        return SettlementStatus.rejected;
      case 'rolled_back':
        return SettlementStatus.rolledBack;
      default:
        return SettlementStatus.pending;
    }
  }
}

class SettlementDto {
  const SettlementDto({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.status,
    this.memo,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final SettlementStatus status;
  final String? memo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SettlementDto.fromJson(Map<String, dynamic> json) {
    return SettlementDto(
      id: json['id'] as String,
      groupId: json['group_id'] as String? ?? '',
      fromUserId: json['from_user'] as String? ?? '',
      toUserId: json['to_user'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'KRW',
      status:
          SettlementStatusX.fromString(json['status'] as String? ?? 'pending'),
      memo: json['memo'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'from_user': fromUserId,
      'to_user': toUserId,
      'amount': amount,
      'currency': currency,
      'status': status.dbValue,
      'memo': memo,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
