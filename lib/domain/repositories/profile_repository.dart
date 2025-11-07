/// 프로필 관련 데이터 접근 인터페이스
abstract class ProfileRepository {
  /// 사용자 프로필 조회
  /// 
  /// [userId] 사용자 ID
  /// 
  /// 반환: 프로필 정보 (없으면 null)
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  /// 사용자 이름 업데이트
  /// 
  /// [userId] 사용자 ID
  /// [name] 새로운 이름
  Future<void> updateName(String userId, String name);

  /// 사용자 닉네임 업데이트
  /// 
  /// [userId] 사용자 ID
  /// [nickname] 새로운 닉네임
  Future<void> updateNickname(String userId, String nickname);
}

