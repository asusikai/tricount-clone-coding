import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/payment_request.dart';

class RequestService {
  RequestService(this._client);

  final SupabaseClient _client;

  Future<List<PaymentRequest>> fetchRequests({
    required String userId,
    PaymentRequestStatus? status,
  }) async {
    try {
      final query = _client
          .from('settlements')
          .select()
          .or('from_user.eq.$userId,to_user.eq.$userId');

      if (status != null) {
        query.eq('status', status.dbValue);
      }

      query.order('created_at', ascending: false);

      final response = await query;
      final rows = List<Map<String, dynamic>>.from(response);

      return _attachLookupData(rows);
    } catch (error, stackTrace) {
      debugPrint('요청 목록 조회 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<PaymentRequest?> fetchRequest(String requestId) async {
    try {
      final response = await _client
          .from('settlements')
          .select()
          .eq('id', requestId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final requests = await _attachLookupData(<Map<String, dynamic>>[
        Map<String, dynamic>.from(response),
      ]);
      return requests.isNotEmpty ? requests.first : null;
    } catch (error, stackTrace) {
      debugPrint('요청 상세 조회 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<PaymentRequest> createRequest({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
    String? memo,
  }) async {
    try {
      final payload = {
        'group_id': groupId,
        'from_user': fromUserId,
        'to_user': toUserId,
        'amount': amount,
        'currency': currency,
        'status': PaymentRequestStatus.pending.dbValue,
        'memo': memo,
      }..removeWhere((key, value) => value == null);

      final response = await _client
          .from('settlements')
          .insert(payload)
          .select()
          .single();

      return (await _attachLookupData(<Map<String, dynamic>>[
        Map<String, dynamic>.from(response),
      ]))
          .first;
    } catch (error, stackTrace) {
      debugPrint('요청 생성 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateStatus({
    required String requestId,
    required PaymentRequestStatus status,
  }) async {
    try {
      await _client
          .from('settlements')
          .update({'status': status.dbValue})
          .eq('id', requestId);
    } catch (error, stackTrace) {
      debugPrint('요청 상태 업데이트 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<List<PaymentRequest>> _attachLookupData(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return <PaymentRequest>[];
    }

    final groupIds = <String>{};
    final userIds = <String>{};

    for (final row in rows) {
      final groupId = row['group_id'] as String?;
      final fromUser = row['from_user'] as String?;
      final toUser = row['to_user'] as String?;
      if (groupId != null) {
        groupIds.add(groupId);
      }
      if (fromUser != null) {
        userIds.add(fromUser);
      }
      if (toUser != null) {
        userIds.add(toUser);
      }
    }

    final groupLookup = <String, Map<String, dynamic>>{};
    final userLookup = <String, Map<String, dynamic>>{};

    if (groupIds.isNotEmpty) {
      try {
        final groupResponse = await _client
            .from('groups')
            .select('id, name, base_currency')
            .inFilter('id', groupIds.toList());
        for (final item in groupResponse) {
          final map = Map<String, dynamic>.from(item);
          groupLookup[map['id'] as String] = map;
        }
      } catch (error) {
        debugPrint('그룹 정보 조회 실패: $error');
      }
    }

    if (userIds.isNotEmpty) {
      try {
        final userResponse = await _client
            .from('users')
            .select('id, name, nickname, email')
            .inFilter('id', userIds.toList());
        for (final item in userResponse) {
          final map = Map<String, dynamic>.from(item);
          userLookup[map['id'] as String] = map;
        }
      } catch (error) {
        debugPrint('사용자 정보 조회 실패: $error');
      }
    }

    return rows
        .map(
          (row) => PaymentRequest.fromRow(
            row,
            groupLookup: groupLookup,
            userLookup: userLookup,
          ),
        )
        .toList(growable: false);
  }
}
