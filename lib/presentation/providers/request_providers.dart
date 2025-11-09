import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../domain/models/models.dart';
import 'repository_providers.dart';

typedef SettlementDetail = ({
  SettlementDto settlement,
  GroupDto? group,
  UserDto? fromUser,
  UserDto? toUser,
});

Future<List<SettlementDetail>> _composeSettlementDetails(
  Ref ref,
  List<SettlementDto> settlements,
) async {
  if (settlements.isEmpty) {
    return const [];
  }

  final groupsRepository = ref.read(groupsRepositoryProvider);
  final usersRepository = ref.read(usersRepositoryProvider);

  final groupIds = settlements.map((s) => s.groupId).toSet().toList();
  final userIds = settlements
      .expand((settlement) => [settlement.fromUserId, settlement.toUserId])
      .toSet()
      .toList();

  final groups = await groupsRepository.fetchByIds(groupIds).unwrap();
  final users = await usersRepository.fetchByIds(userIds).unwrap();

  final groupLookup = {for (final group in groups) group.id: group};
  final userLookup = {for (final user in users) user.id: user};

  return settlements
      .map(
        (settlement) => (
          settlement: settlement,
          group: groupLookup[settlement.groupId],
          fromUser: userLookup[settlement.fromUserId],
          toUser: userLookup[settlement.toUserId],
        ),
      )
      .toList(growable: false);
}

final requestListProvider = FutureProvider.autoDispose
    .family<List<SettlementDetail>, SettlementStatus?>((ref, status) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return const [];
  }

  final repository = ref.watch(settlementsRepositoryProvider);
  final result = await repository.fetchByUser(user.id);
  var settlements = result.requireValue;

  if (status != null) {
    settlements = settlements
        .where((item) => item.status == status)
        .toList(growable: false);
  }

  return _composeSettlementDetails(ref, settlements);
});

final requestDetailProvider = FutureProvider.autoDispose
    .family<SettlementDetail?, String>((ref, settlementId) async {
  final repository = ref.watch(settlementsRepositoryProvider);
  final result = await repository.fetchById(settlementId);
  final settlement = result.fold(
    onSuccess: (value) => value,
    onFailure: (error) => throw error,
  );
  final details = await _composeSettlementDetails(ref, [settlement]);
  return details.isEmpty ? null : details.first;
});
