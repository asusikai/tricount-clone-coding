import 'package:intl/intl.dart';

/// 날짜 포맷팅 유틸리티
///
/// 앱 전역에서 사용하는 날짜 포맷팅 함수들을 제공합니다.
class DateFormatter {
  DateFormatter._();

  /// 기본 날짜 시간 포맷 (yyyy.MM.dd HH:mm)
  ///
  /// 예: 2024.11.07 14:30
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy.MM.dd HH:mm').format(dateTime.toLocal());
  }

  /// 날짜만 포맷 (yyyy.MM.dd)
  ///
  /// 예: 2024.11.07
  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy.MM.dd').format(dateTime.toLocal());
  }

  /// 시간만 포맷 (HH:mm)
  ///
  /// 예: 14:30
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime.toLocal());
  }

  /// ISO 8601 문자열을 DateTime으로 파싱 후 포맷
  ///
  /// [dateString] ISO 8601 형식의 날짜 문자열
  /// [formatter] 사용할 포맷터 함수 (기본값: formatDateTime)
  ///
  /// 반환: 포맷된 날짜 문자열, 파싱 실패 시 null
  static String? formatFromString(
    String? dateString, {
    String Function(DateTime)? formatter,
  }) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }

    final dateTime = DateTime.tryParse(dateString);
    if (dateTime == null) {
      return null;
    }

    final formatFunc = formatter ?? formatDateTime;
    return formatFunc(dateTime);
  }

  /// ISO 8601 문자열을 DateTime으로 파싱
  ///
  /// [dateString] ISO 8601 형식의 날짜 문자열
  ///
  /// 반환: DateTime 객체, 파싱 실패 시 null
  static DateTime? parseFromString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    return DateTime.tryParse(dateString);
  }
}
