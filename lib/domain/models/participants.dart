class ParticipantShare {
  const ParticipantShare({
    required this.userId,
    required this.ratio,
    this.amount,
  });

  final String userId;
  final double ratio;
  final double? amount;

  factory ParticipantShare.fromJson(Map<String, dynamic> json) {
    return ParticipantShare(
      userId: json['user_id'] as String? ?? '',
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'ratio': ratio,
      'amount': amount,
    }..removeWhere((key, value) => value == null);
  }
}
