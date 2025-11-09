import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/expenses_repository.dart';
import 'supabase_mapper.dart';

class SupabaseExpensesRepository implements ExpensesRepository {
  SupabaseExpensesRepository(this._client);

  final SupabaseClient _client;

  @override
  ResultFuture<List<ExpenseDto>> fetchByGroup(String groupId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('expenses')
            .select()
            .eq('group_id', groupId)
            .order('expense_date', ascending: false);
        return mapRows(response)
            .map(ExpenseDto.fromJson)
            .toList(growable: false);
      },
      context: '지출 목록 조회 실패',
    );
  }

  @override
  ResultFuture<ExpenseDto> fetchById(String expenseId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('expenses')
            .select()
            .eq('id', expenseId)
            .maybeSingle();
        if (response == null) {
          throw const NotFoundException('지출을 찾을 수 없습니다.');
        }
        return ExpenseDto.fromJson(mapRow(response));
      },
      context: '지출 상세 조회 실패',
    );
  }

  @override
  ResultFuture<ExpenseDto> create({
    required String groupId,
    required String payerId,
    required String createdBy,
    required double amount,
    required String currency,
    required DateTime expenseDate,
    required List<ParticipantShare> participants,
    String? description,
  }) {
    return ErrorHandler.guardAsync(
      () async {
        final payload = {
          'group_id': groupId,
          'payer_id': payerId,
          'created_by': createdBy,
          'amount': amount,
          'currency': currency,
          'expense_date': expenseDate.toIso8601String(),
          'description': description,
          'participants':
              participants.map((share) => share.toJson()).toList(),
        }..removeWhere((key, value) => value == null);

        final response = await _client
            .from('expenses')
            .insert(payload)
            .select()
            .single();
        return ExpenseDto.fromJson(mapRow(response));
      },
      context: '지출 생성 실패',
    );
  }

  @override
  ResultFuture<ExpenseDto> update({
    required String expenseId,
    double? amount,
    String? currency,
    DateTime? expenseDate,
    String? description,
    List<ParticipantShare>? participants,
  }) {
    return ErrorHandler.guardAsync(
      () async {
        final payload = <String, dynamic>{
          if (amount != null) 'amount': amount,
          if (currency != null) 'currency': currency,
          if (expenseDate != null)
            'expense_date': expenseDate.toIso8601String(),
          if (description != null) 'description': description,
          if (participants != null)
            'participants': participants.map((e) => e.toJson()).toList(),
        };
        if (payload.isEmpty) {
          return (await fetchById(expenseId)).requireValue;
        }
        final response = await _client
            .from('expenses')
            .update(payload)
            .eq('id', expenseId)
            .select()
            .single();
        return ExpenseDto.fromJson(mapRow(response));
      },
      context: '지출 수정 실패',
    );
  }

  @override
  ResultFuture<void> delete(String expenseId) {
    return ErrorHandler.guardAsync(
      () async {
        await _client.from('expenses').delete().eq('id', expenseId);
      },
      context: '지출 삭제 실패',
    );
  }
}
