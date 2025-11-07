/// 그룹 관련 데이터 접근 인터페이스
abstract class GroupRepository {
  /// 그룹 생성
  /// 
  /// [name] 그룹 이름
  /// [baseCurrency] 기본 통화 (예: 'KRW', 'USD')
  /// 
  /// 반환: 생성된 그룹 ID
  Future<String> createGroup({
    required String name,
    required String baseCurrency,
  });

  /// 초대 코드로 그룹 가입
  /// 
  /// [inviteCode] 초대 코드 (UUID)
  /// 
  /// 반환: 가입한 그룹 ID
  Future<String> joinGroupByInviteCode(String inviteCode);

  /// 사용자가 가입한 그룹 목록 조회
  Future<List<Map<String, dynamic>>> getUserGroups();

  /// 그룹 멤버 목록 조회 (사용자 정보 포함)
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId);

  /// 그룹 상세 정보 조회
  Future<Map<String, dynamic>> getGroupDetail(String groupId);

  /// 그룹 삭제 (소유자만 가능)
  Future<void> deleteGroup(String groupId);

  /// 그룹 초대 링크 생성
  /// 
  /// [groupId] 그룹 ID
  /// 
  /// 반환: 딥링크 URL
  Future<String> getInviteLink(String groupId);
}

