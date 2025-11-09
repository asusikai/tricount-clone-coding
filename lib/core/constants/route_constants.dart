/// 라우트 경로 상수
/// 
/// 앱 전역에서 사용하는 라우트 경로를 정의합니다.
class RouteConstants {
  RouteConstants._();

  // 기본 라우트
  static const String splash = '/splash';
  static const String auth = '/auth';
  static const String home = '/home';

  // 그룹 관련
  static String groupDetail(String id) => '/groups/${Uri.encodeComponent(id)}';

  // 요청 관련
  static const String requestRegister = '/requests/register';
  static String requestDetail(String id) => '/requests/$id';

  // OAuth 콜백
  static const String authKakao = '/auth/kakao';
  static const String authGoogle = '/auth/google';
  static const String authApple = '/auth/apple';
}
