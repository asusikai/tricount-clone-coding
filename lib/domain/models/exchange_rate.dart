import 'package:freezed_annotation/freezed_annotation.dart';

part 'exchange_rate.freezed.dart';
part 'exchange_rate.g.dart';

@freezed
class ExchangeRateDto with _$ExchangeRateDto {
  const factory ExchangeRateDto({
    @JsonKey(name: 'base_currency') required String baseCurrency,
    required String currency,
    required double rate,
    @JsonKey(name: 'rate_date') required DateTime rateDate,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _ExchangeRateDto;

  factory ExchangeRateDto.fromJson(Map<String, dynamic> json) =>
      _$ExchangeRateDtoFromJson(json);
}
