enum MembershipRole {
  owner,
  admin,
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

  String get dbValue {
    switch (this) {
      case MembershipRole.owner:
        return 'owner';
      case MembershipRole.admin:
        return 'admin';
      case MembershipRole.member:
        return 'member';
    }
  }

  static MembershipRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return MembershipRole.owner;
      case 'admin':
        return MembershipRole.admin;
      default:
        return MembershipRole.member;
    }
  }
}

class MemberDto {
  const MemberDto({
    required this.id,
    required this.userId,
    required this.groupId,
    this.joinedAt,
    required this.role,
  });

  final String id;
  final String userId;
  final String groupId;
  final DateTime? joinedAt;
  final MembershipRole role;

  factory MemberDto.fromJson(Map<String, dynamic> json) {
    return MemberDto(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      groupId: json['group_id'] as String? ?? '',
      joinedAt: _parseDateTime(json['joined_at']),
      role: MembershipRoleX.fromString(json['role'] as String? ?? 'member'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'group_id': groupId,
      'joined_at': joinedAt?.toIso8601String(),
      'role': role.dbValue,
    }..removeWhere((key, value) => value == null);
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
