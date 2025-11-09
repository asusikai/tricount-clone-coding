import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/supabase_exchange_rates_repository.dart';
import '../../data/repositories/supabase_expenses_repository.dart';
import '../../data/repositories/supabase_groups_repository.dart';
import '../../data/repositories/supabase_members_repository.dart';
import '../../data/repositories/supabase_settlements_repository.dart';
import '../../data/repositories/supabase_users_repository.dart';
import '../../domain/repositories/exchange_rates_repository.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../domain/repositories/members_repository.dart';
import '../../domain/repositories/settlements_repository.dart';
import '../../domain/repositories/users_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseUsersRepository(client);
});

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseGroupsRepository(client);
});

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseMembersRepository(client);
});

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseExpensesRepository(client);
});

final settlementsRepositoryProvider =
    Provider<SettlementsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseSettlementsRepository(client);
});

final exchangeRatesRepositoryProvider =
    Provider<ExchangeRatesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseExchangeRatesRepository(client);
});
