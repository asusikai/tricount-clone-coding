/// 앱 전역 상수
/// 
/// 앱 전역에서 사용하는 상수들을 정의합니다.
class AppConstants {
  AppConstants._();

  // 그룹 관련
  /// 그룹 이름 최대 길이
  static const int maxGroupNameLength = 50;

  /// 그룹 이름 최소 길이
  static const int minGroupNameLength = 1;

  // UI 관련
  /// 기본 패딩
  static const double defaultPadding = 16.0;

  /// 큰 패딩
  static const double largePadding = 24.0;

  /// 작은 패딩
  static const double smallPadding = 8.0;

  // 네트워크 관련
  /// 요청 타임아웃 (초)
  static const int requestTimeoutSeconds = 30;

  // 딥링크 관련
  /// 딥링크 스킴
  static const String deepLinkScheme = 'splitbills';

  /// 초대 링크 호스트
  static const String inviteLinkHost = 'invite';

  /// 초대 링크 파라미터 이름
  static const String inviteCodeParameter = 'code';
}

