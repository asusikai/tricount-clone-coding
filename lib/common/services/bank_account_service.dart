import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/bank_account_repository_impl.dart';
import '../../domain/repositories/bank_account_repository.dart';

/// 계좌 관련 서비스 클래스
/// 
/// 내부적으로 BankAccountRepository를 사용하여 데이터 접근을 처리합니다.
class BankAccountService {
  BankAccountService(this._repository);

  final BankAccountRepository _repository;

  /// SupabaseClient를 직접 받는 생성자 (하위 호환성)
  BankAccountService.fromClient(SupabaseClient client)
      : _repository = BankAccountRepositoryImpl(client);

  Future<List<Map<String, dynamic>>> fetchAccounts(String userId) =>
      _repository.fetchAccounts(userId);

  Future<Map<String, dynamic>> addAccount({
    required String userId,
    required String bankName,
    required String accountNumber,
    String? accountHolder,
    String? memo,
    bool isPublic = false,
  }) =>
      _repository.addAccount(
        userId: userId,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolder: accountHolder,
        memo: memo,
        isPublic: isPublic,
      );

  Future<void> deleteAccount(String accountId) =>
      _repository.deleteAccount(accountId);
}
