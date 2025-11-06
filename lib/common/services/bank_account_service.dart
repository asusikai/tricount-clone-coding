import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BankAccountService {
  const BankAccountService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchAccounts(String userId) async {
    try {
      final response = await _client
          .from('bank_accounts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error, stackTrace) {
      debugPrint('계좌 조회 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
    return [];
  }

  Future<Map<String, dynamic>> addAccount({
    required String userId,
    required String bankName,
    required String accountNumber,
    String? accountHolder,
    String? memo,
    bool isPublic = false,
  }) async {
    try {
      final payload = {
        'user_id': userId,
        'bank_name': bankName.trim(),
        'account_number': accountNumber.trim(),
        'is_public': isPublic,
        if (accountHolder != null && accountHolder.trim().isNotEmpty)
          'account_holder': accountHolder.trim(),
        if (memo != null && memo.trim().isNotEmpty) 'memo': memo.trim(),
      };

      final response = await _client
          .from('bank_accounts')
          .insert(payload)
          .select()
          .single();
      return Map<String, dynamic>.from(response);
    } catch (error, stackTrace) {
      debugPrint('계좌 추가 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    try {
      await _client
          .from('bank_accounts')
          .delete()
          .eq('id', accountId);
    } catch (error, stackTrace) {
      debugPrint('계좌 삭제 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final bankAccountServiceProvider = Provider<BankAccountService>((ref) {
  return BankAccountService(Supabase.instance.client);
});
