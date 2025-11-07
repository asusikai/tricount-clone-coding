import '../../common/models/payment_request.dart';
import '../repositories/request_repository.dart';

/// 정산 요청 목록 조회 UseCase
class FetchRequestsUseCase {
  FetchRequestsUseCase(this._repository);

  final RequestRepository _repository;

  /// 정산 요청 목록 조회
  /// 
  /// [userId] 사용자 ID
  /// [status] 필터링할 상태 (선택사항)
  Future<List<PaymentRequest>> call({
    required String userId,
    PaymentRequestStatus? status,
  }) =>
      _repository.fetchRequests(
        userId: userId,
        status: status,
      );
}

