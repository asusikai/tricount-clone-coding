class GroupDto {
  const GroupDto({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
    required this.baseCurrency,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;
  final String baseCurrency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory GroupDto.fromJson(Map<String, dynamic> json) {
    return GroupDto(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      inviteCode: json['invite_code'] as String? ?? '',
      baseCurrency: json['base_currency'] as String? ?? 'KRW',
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'invite_code': inviteCode,
      'base_currency': baseCurrency,
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
