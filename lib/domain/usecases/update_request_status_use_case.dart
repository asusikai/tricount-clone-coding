import '../../common/models/payment_request.dart';
import '../repositories/request_repository.dart';

/// 정산 요청 상태 업데이트 UseCase
class UpdateRequestStatusUseCase {
  UpdateRequestStatusUseCase(this._repository);

  final RequestRepository _repository;

  /// 정산 요청 상태 업데이트
  /// 
  /// [requestId] 요청 ID
  /// [status] 새로운 상태
  Future<void> call({
    required String requestId,
    required PaymentRequestStatus status,
  }) =>
      _repository.updateStatus(
        requestId: requestId,
        status: status,
      );
}

