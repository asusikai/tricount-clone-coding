import '../../common/models/payment_request.dart';
import '../repositories/request_repository.dart';

/// 정산 요청 상세 조회 UseCase
class FetchRequestUseCase {
  FetchRequestUseCase(this._repository);

  final RequestRepository _repository;

  /// 정산 요청 상세 조회
  /// 
  /// [requestId] 요청 ID
  /// 
  /// 반환: 요청 정보 (없으면 null)
  Future<PaymentRequest?> call(String requestId) =>
      _repository.fetchRequest(requestId);
}

