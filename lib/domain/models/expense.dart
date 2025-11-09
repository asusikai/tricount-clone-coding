import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters/participants_converter.dart';
import 'participants.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

@freezed
class ExpenseDto with _$ExpenseDto {
  const factory ExpenseDto({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'payer_id') required String payerId,
    @JsonKey(name: 'created_by') required String createdBy,
    required double amount,
    String? description,
    @JsonKey(name: 'expense_date') required DateTime expenseDate,
    required String currency,
    @JsonKey(name: 'participants')
    @ParticipantsConverter()
    required List<ParticipantShare> participants,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ExpenseDto;

  factory ExpenseDto.fromJson(Map<String, dynamic> json) =>
      _$ExpenseDtoFromJson(json);
}
