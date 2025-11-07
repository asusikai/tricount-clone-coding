import '../../common/models/payment_request.dart';
import '../repositories/request_repository.dart';

/// 정산 요청 생성 UseCase
class CreateRequestUseCase {
  CreateRequestUseCase(this._repository);

  final RequestRepository _repository;

  /// 정산 요청 생성
  /// 
  /// [groupId] 그룹 ID
  /// [fromUserId] 송금 보내는 사용자 ID
  /// [toUserId] 송금 받는 사용자 ID
  /// [amount] 금액
  /// [currency] 통화
  /// [memo] 메모 (선택사항)
  Future<PaymentRequest> call({
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
}

