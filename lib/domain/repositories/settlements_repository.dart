import '../../core/errors/errors.dart';
import '../models/models.dart';

abstract class SettlementsRepository {
  ResultFuture<List<SettlementDto>> fetchByGroup(String groupId);

  ResultFuture<List<SettlementDto>> fetchByUser(String userId);

  ResultFuture<SettlementDto> fetchById(String settlementId);

  ResultFuture<SettlementDto> create({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    String? memo,
  });

  ResultFuture<SettlementDto> updateStatus({
    required String settlementId,
    required SettlementStatus status,
  });
}
