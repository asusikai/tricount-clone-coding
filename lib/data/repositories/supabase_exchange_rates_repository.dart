import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/exchange_rates_repository.dart';
import 'supabase_mapper.dart';

class SupabaseExchangeRatesRepository implements ExchangeRatesRepository {
  SupabaseExchangeRatesRepository(this._client);

  final SupabaseClient _client;

  @override
  ResultFuture<ExchangeRateDto> fetchLatest({
    required String baseCurrency,
    required String currency,
  }) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('exchange_rates')
            .select()
            .eq('base_currency', baseCurrency)
            .eq('currency', currency)
            .order('rate_date', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response == null) {
          throw const NotFoundException('환율 정보를 찾을 수 없습니다.');
        }
        return ExchangeRateDto.fromJson(mapRow(response));
      },
      context: '환율 조회 실패',
    );
  }

  @override
  ResultFuture<void> upsert(ExchangeRateDto rate) {
    return ErrorHandler.guardAsync(
      () async {
        await _client
            .from('exchange_rates')
            .upsert(rate.toJson());
      },
      context: '환율 저장 실패',
    );
  }
}
