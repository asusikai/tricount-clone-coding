class ExchangeRateDto {
  const ExchangeRateDto({
    required this.baseCurrency,
    required this.currency,
    required this.rate,
    required this.rateDate,
    this.updatedAt,
  });

  final String baseCurrency;
  final String currency;
  final double rate;
  final DateTime rateDate;
  final DateTime? updatedAt;

  factory ExchangeRateDto.fromJson(Map<String, dynamic> json) {
    return ExchangeRateDto(
      baseCurrency: json['base_currency'] as String? ?? 'KRW',
      currency: json['currency'] as String? ?? 'KRW',
      rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
      rateDate: _parseDate(json['rate_date']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_currency': baseCurrency,
      'currency': currency,
      'rate': rate,
      'rate_date': rateDate.toIso8601String(),
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
