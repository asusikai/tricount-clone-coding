import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';
part 'group.g.dart';

@freezed
class GroupDto with _$GroupDto {
  const factory GroupDto({
    required String id,
    required String name,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'invite_code') required String inviteCode,
    @JsonKey(name: 'base_currency') required String baseCurrency,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _GroupDto;

  factory GroupDto.fromJson(Map<String, dynamic> json) =>
      _$GroupDtoFromJson(json);
}
