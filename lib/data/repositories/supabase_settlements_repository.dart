import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/settlements_repository.dart';
import 'supabase_mapper.dart';

class SupabaseSettlementsRepository implements SettlementsRepository {
  SupabaseSettlementsRepository(this._client);

  final SupabaseClient _client;

  @override
  ResultFuture<List<SettlementDto>> fetchByGroup(String groupId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('settlements')
            .select()
            .eq('group_id', groupId)
            .order('created_at', ascending: false);
        return mapRows(response)
            .map(SettlementDto.fromJson)
            .toList(growable: false);
      },
      context: '정산 요청(그룹) 조회 실패',
    );
  }

  @override
  ResultFuture<List<SettlementDto>> fetchByUser(String userId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('settlements')
            .select()
            .or('from_user.eq.$userId,to_user.eq.$userId')
            .order('created_at', ascending: false);
        return mapRows(response)
            .map(SettlementDto.fromJson)
            .toList(growable: false);
      },
      context: '정산 요청(사용자) 조회 실패',
    );
  }

  @override
  ResultFuture<SettlementDto> fetchById(String settlementId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('settlements')
            .select()
            .eq('id', settlementId)
            .maybeSingle();
        if (response == null) {
          throw const NotFoundException('정산 요청을 찾을 수 없습니다.');
        }
        return SettlementDto.fromJson(mapRow(response));
      },
      context: '정산 요청 상세 조회 실패',
    );
  }

  @override
  ResultFuture<SettlementDto> create({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    String? memo,
  }) {
    return ErrorHandler.guardAsync(
      () async {
        final payload = {
          'group_id': groupId,
          'from_user': fromUserId,
          'to_user': toUserId,
          'amount': amount,
          'currency': currency,
          'memo': memo,
          'status': SettlementStatus.pending.dbValue,
        }..removeWhere((key, value) => value == null);

        final response = await _client
            .from('settlements')
            .insert(payload)
            .select()
            .single();
        return SettlementDto.fromJson(mapRow(response));
      },
      context: '정산 요청 생성 실패',
    );
  }

  @override
  ResultFuture<SettlementDto> updateStatus({
    required String settlementId,
    required SettlementStatus status,
  }) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('settlements')
            .update({'status': status.dbValue})
            .eq('id', settlementId)
            .select()
            .single();
        return SettlementDto.fromJson(mapRow(response));
      },
      context: '정산 요청 상태 변경 실패',
    );
  }
}
