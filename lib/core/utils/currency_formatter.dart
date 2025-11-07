import 'package:intl/intl.dart';

/// 통화 포맷팅 유틸리티
///
/// 금액과 통화 코드를 포맷팅하는 함수들을 제공합니다.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// 간단한 통화 포맷 (소수점 없음)
  ///
  /// 예: 1000 KRW
  ///
  /// [amount] 금액
  /// [currency] 통화 코드 (기본값: 'KRW')
  static String formatSimple(double amount, {String currency = 'KRW'}) {
    return '${amount.toStringAsFixed(0)} $currency';
  }

  /// 소수점 포함 통화 포맷
  ///
  /// 예: 1000.00 KRW
  ///
  /// [amount] 금액
  /// [currency] 통화 코드 (기본값: 'KRW')
  /// [decimalPlaces] 소수점 자릿수 (기본값: 2)
  static String formatWithDecimals(
    double amount, {
    String currency = 'KRW',
    int decimalPlaces = 2,
  }) {
    return '${amount.toStringAsFixed(decimalPlaces)} $currency';
  }

  /// NumberFormat을 사용한 지역화된 통화 포맷
  ///
  /// 예: ₩1,000 (KRW), $1,000.00 (USD)
  ///
  /// [amount] 금액
  /// [currency] 통화 코드
  /// [locale] 로케일 (기본값: 'ko_KR')
  static String formatLocalized(
    double amount,
    String currency, {
    String locale = 'ko_KR',
  }) {
    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: _getCurrencySymbol(currency),
      decimalDigits: _getDecimalDigits(currency),
    );
    return formatter.format(amount);
  }

  /// 통화 코드에 따른 통화 심볼 반환
  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'KRW':
        return '₩';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'GBP':
        return '£';
      default:
        return currency;
    }
  }

  /// 통화 코드에 따른 소수점 자릿수 반환
  static int _getDecimalDigits(String currency) {
    switch (currency.toUpperCase()) {
      case 'JPY':
      case 'KRW':
        return 0; // 원화와 엔화는 소수점 없음
      default:
        return 2;
    }
  }
}
