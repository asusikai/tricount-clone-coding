/// 계좌 관련 데이터 접근 인터페이스
abstract class BankAccountRepository {
  /// 사용자 계좌 목록 조회
  /// 
  /// [userId] 사용자 ID
  Future<List<Map<String, dynamic>>> fetchAccounts(String userId);

  /// 계좌 추가
  /// 
  /// [userId] 사용자 ID
  /// [bankName] 은행명
  /// [accountNumber] 계좌번호
  /// [accountHolder] 예금주 (선택사항)
  /// [memo] 메모 (선택사항)
  /// [isPublic] 공개 여부
  /// 
  /// 반환: 생성된 계좌 정보
  Future<Map<String, dynamic>> addAccount({
    required String userId,
    required String bankName,
    required String accountNumber,
    String? accountHolder,
    String? memo,
    bool isPublic = false,
  });

  /// 계좌 삭제
  /// 
  /// [accountId] 계좌 ID
  Future<void> deleteAccount(String accountId);
}

