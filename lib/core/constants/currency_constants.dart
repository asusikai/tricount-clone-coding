/// 통화 관련 상수
/// 
/// 앱에서 사용하는 통화 코드와 기본값을 정의합니다.
class CurrencyConstants {
  CurrencyConstants._();

  /// 지원하는 통화 목록
  static const List<String> supportedCurrencies = [
    'KRW',
    'USD',
    'EUR',
    'JPY',
    'CNY',
    'GBP',
  ];

  /// 기본 통화 코드
  static const String defaultCurrency = 'KRW';

  /// 통화가 지원되는지 확인
  static bool isSupported(String currency) {
    return supportedCurrencies.contains(currency.toUpperCase());
  }

  /// 통화 코드를 대문자로 정규화
  static String normalize(String currency) {
    return currency.toUpperCase();
  }
}

