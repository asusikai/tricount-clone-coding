import 'converters/participants_converter.dart';
import 'participants.dart';

class ExpenseDto {
  const ExpenseDto({
    required this.id,
    required this.groupId,
    required this.payerId,
    required this.createdBy,
    required this.amount,
    required this.expenseDate,
    required this.currency,
    required this.participants,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String groupId;
  final String payerId;
  final String createdBy;
  final double amount;
  final String? description;
  final DateTime expenseDate;
  final String currency;
  final List<ParticipantShare> participants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ExpenseDto.fromJson(Map<String, dynamic> json) {
    return ExpenseDto(
      id: json['id'] as String,
      groupId: json['group_id'] as String? ?? '',
      payerId: json['payer_id'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
      expenseDate: _parseDate(json['expense_date']) ?? DateTime.now(),
      currency: json['currency'] as String? ?? 'KRW',
      participants: const ParticipantsConverter().fromJson(json['participants']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'payer_id': payerId,
      'created_by': createdBy,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String(),
      'currency': currency,
      'participants':
          participants.map((participant) => participant.toJson()).toList(),
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
