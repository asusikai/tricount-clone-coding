import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_request.dart';
import '../../data/repositories/request_repository_impl.dart';
import '../../domain/repositories/request_repository.dart';

/// 정산 요청 관련 서비스 클래스
/// 
/// 내부적으로 RequestRepository를 사용하여 데이터 접근을 처리합니다.
class RequestService {
  RequestService(this._repository);

  final RequestRepository _repository;

  /// SupabaseClient를 직접 받는 생성자 (하위 호환성)
  RequestService.fromClient(SupabaseClient client)
      : _repository = RequestRepositoryImpl(client);

  Future<List<PaymentRequest>> fetchRequests({
    required String userId,
    PaymentRequestStatus? status,
  }) =>
      _repository.fetchRequests(userId: userId, status: status);

  Future<PaymentRequest?> fetchRequest(String requestId) =>
      _repository.fetchRequest(requestId);

  Future<PaymentRequest> createRequest({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    String? memo,
  }) =>
      _repository.createRequest(
        groupId: groupId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: amount,
        currency: currency,
        memo: memo,
      );

  Future<void> updateStatus({
    required String requestId,
    required PaymentRequestStatus status,
  }) =>
      _repository.updateStatus(requestId: requestId, status: status);
}
