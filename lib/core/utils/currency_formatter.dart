import 'package:intl/intl.dart';

/// 통화 포맷팅 유틸리티
///
/// NumberFormat.currency를 감싸 로케일/소수점/심볼을 유연하게 제어합니다.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// 로케일/심볼을 고려한 통화 포맷
  static String format(
    double amount, {
    String currency = 'KRW',
    String? locale,
    int? decimalDigits,
    bool withSymbol = true,
  }) {
    final resolvedCurrency =
        currency.isEmpty ? 'KRW' : currency.toUpperCase();
    final resolvedLocale = _resolveLocale(locale);
    final digits = decimalDigits ?? _defaultDecimalDigits(resolvedCurrency);
    final symbol = withSymbol ? _symbolFor(resolvedCurrency) : '';

    try {
      final formatter = NumberFormat.currency(
        locale: resolvedLocale,
        name: resolvedCurrency,
        symbol: symbol,
        decimalDigits: digits,
      );
      final formatted = formatter.format(amount);
      if (withSymbol && symbol.isNotEmpty) {
        return formatted;
      }
      return '$formatted $resolvedCurrency'.trim();
    } catch (_) {
      final fallback = amount.toStringAsFixed(digits);
      return withSymbol
          ? '$fallback $resolvedCurrency'
          : '$fallback $resolvedCurrency'.trim();
    }
  }

  /// 간단한 정수 통화 포맷 (ex. "1,000 KRW")
  static String formatSimple(double amount, {String currency = 'KRW'}) {
    final digits = _defaultDecimalDigits(currency.toUpperCase());
    return format(
      amount,
      currency: currency,
      decimalDigits: digits == 0 ? 0 : digits,
      withSymbol: false,
    );
  }

  /// 소수점 고정 포맷
  static String formatWithDecimals(
    double amount, {
    String currency = 'KRW',
    int decimalPlaces = 2,
  }) {
    return format(
      amount,
      currency: currency,
      decimalDigits: decimalPlaces,
      withSymbol: false,
    );
  }

  /// 로케일 기반 포맷 (기존 API와 호환)
  static String formatLocalized(
    double amount,
    String currency, {
    String locale = 'ko_KR',
  }) {
    return format(
      amount,
      currency: currency,
      locale: locale,
    );
  }

  static String _resolveLocale(String? locale) {
    if (locale == null || locale.isEmpty) {
      final current = Intl.getCurrentLocale();
      return current.isEmpty ? 'ko_KR' : current;
    }
    return Intl.canonicalizedLocale(locale);
  }

  static int _defaultDecimalDigits(String currency) {
    switch (currency) {
      case 'KRW':
      case 'JPY':
      case 'VND':
        return 0;
      default:
        return 2;
    }
  }

  static String _symbolFor(String currency) {
    switch (currency) {
      case 'KRW':
        return '₩';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'GBP':
        return '£';
      case 'CNY':
        return '¥';
      default:
        return currency;
    }
  }
}
