import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum MembershipRole {
  @JsonValue('owner')
  owner,
  @JsonValue('admin')
  admin,
  @JsonValue('member')
  member,
}

extension MembershipRoleX on MembershipRole {
  String get label {
    switch (this) {
      case MembershipRole.owner:
        return '소유자';
      case MembershipRole.admin:
        return '관리자';
      case MembershipRole.member:
        return '멤버';
    }
  }

  String get dbValue => _$MembershipRoleEnumMap[this]!;
}

@freezed
class MemberDto with _$MemberDto {
  const factory MemberDto({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'joined_at') DateTime? joinedAt,
    required MembershipRole role,
  }) = _MemberDto;

  factory MemberDto.fromJson(Map<String, dynamic> json) =>
      _$MemberDtoFromJson(json);
}
