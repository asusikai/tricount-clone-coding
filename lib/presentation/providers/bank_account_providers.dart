import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/bank_account_service.dart';

/// 계좌 서비스 Provider
final bankAccountServiceProvider = Provider<BankAccountService>((ref) {
  return BankAccountService(Supabase.instance.client);
});

