class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    this.name,
    this.nickname,
    this.provider,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String? name;
  final String? nickname;
  final String? provider;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      nickname: json['nickname'] as String?,
      provider: json['provider'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'nickname': nickname,
      'provider': provider,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
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
