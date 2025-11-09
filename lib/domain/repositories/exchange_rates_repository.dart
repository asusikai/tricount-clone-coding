import '../../core/errors/errors.dart';
import '../models/models.dart';

abstract class ExchangeRatesRepository {
  ResultFuture<ExchangeRateDto> fetchLatest({
    required String baseCurrency,
    required String currency,
  });

  ResultFuture<void> upsert(ExchangeRateDto rate);
}
