import '../../common/models/payment_request.dart';

/// 정산 요청 관련 데이터 접근 인터페이스
abstract class RequestRepository {
  /// 정산 요청 목록 조회
  /// 
  /// [userId] 사용자 ID
  /// [status] 필터링할 상태 (선택사항)
  Future<List<PaymentRequest>> fetchRequests({
    required String userId,
    PaymentRequestStatus? status,
  });

  /// 정산 요청 상세 조회
  /// 
  /// [requestId] 요청 ID
  /// 
  /// 반환: 요청 정보 (없으면 null)
  Future<PaymentRequest?> fetchRequest(String requestId);

  /// 정산 요청 생성
  /// 
  /// [groupId] 그룹 ID
  /// [fromUserId] 송금 보내는 사용자 ID
  /// [toUserId] 송금 받는 사용자 ID
  /// [amount] 금액
  /// [currency] 통화
  /// [memo] 메모 (선택사항)
  Future<PaymentRequest> createRequest({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    String? memo,
  });

  /// 정산 요청 상태 업데이트
  /// 
  /// [requestId] 요청 ID
  /// [status] 새로운 상태
  Future<void> updateStatus({
    required String requestId,
    required PaymentRequestStatus status,
  });
}

