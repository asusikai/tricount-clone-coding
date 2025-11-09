import 'package:freezed_annotation/freezed_annotation.dart';

part 'settlement.freezed.dart';
part 'settlement.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum SettlementStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('paid')
  paid,
  @JsonValue('rejected')
  rejected,
  @JsonValue('rolled_back')
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

  String get dbValue => _$SettlementStatusEnumMap[this]!;
}

@freezed
class SettlementDto with _$SettlementDto {
  const factory SettlementDto({
    required String id,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'from_user') required String fromUserId,
    @JsonKey(name: 'to_user') required String toUserId,
    required double amount,
    required String currency,
    required SettlementStatus status,
    String? memo,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _SettlementDto;

  factory SettlementDto.fromJson(Map<String, dynamic> json) =>
      _$SettlementDtoFromJson(json);
}
