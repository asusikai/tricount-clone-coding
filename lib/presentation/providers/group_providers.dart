import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/errors.dart';
import '../../domain/models/models.dart';
import 'repository_providers.dart';

typedef GroupMemberDetail = ({MemberDto member, UserDto? user});

class GroupListController extends AsyncNotifier<List<GroupDto>> {
  GroupListController();

  static const _cacheDuration = Duration(minutes: 1);
  final _uuid = const Uuid();
  DateTime? _lastFetched;

  @override
  Future<List<GroupDto>> build() async {
    return _load(force: true);
  }

  Future<List<GroupDto>> _load({required bool force}) async {
    final cached = state.maybeWhen<List<GroupDto>?>(
      data: (value) => value,
      orElse: () => null,
    );
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      _lastFetched = DateTime.now();
      return const <GroupDto>[];
    }

    if (!force &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!) < _cacheDuration &&
        cached != null) {
      return cached;
    }

    final repository = ref.read(groupsRepositoryProvider);
    final result = await repository.fetchByUser(userId);
    return result.fold(
      onSuccess: (groups) {
        _lastFetched = DateTime.now();
        return groups;
      },
      onFailure: (error) => throw error,
    );
  }

  Future<void> refresh({bool force = true}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(force: force));
  }

  Future<void> refreshIfStale() async {
    final shouldRefresh = _lastFetched == null ||
        DateTime.now().difference(_lastFetched!) >= _cacheDuration;
    if (!shouldRefresh) {
      return;
    }
    state = await AsyncValue.guard(() => _load(force: true));
  }

  Future<Result<GroupDto>> createGroup({
    required String name,
    required String baseCurrency,
  }) async {
    final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (userId == null) {
      return Failure(const AuthException('로그인이 필요합니다.'));
    }

    final optimistic = GroupDto(
      id: _uuid.v4(),
      name: name,
      ownerId: userId,
      inviteCode: 'pending',
      baseCurrency: baseCurrency,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final previous = state;
    state = previous.maybeWhen(
      data: (groups) => AsyncData(<GroupDto>[optimistic, ...groups]),
      orElse: () => AsyncData(<GroupDto>[optimistic]),
    );

    final result = await ref
        .read(groupsRepositoryProvider)
        .create(ownerId: userId, name: name, baseCurrency: baseCurrency);

    return result.fold(
      onSuccess: (group) {
        _lastFetched = DateTime.now();
        state = state.whenData((groups) {
          final filtered =
              groups.where((item) => item.id != optimistic.id).toList();
          return <GroupDto>[group, ...filtered];
        });
        return Success(group);
      },
      onFailure: (error) {
        state = previous;
        return Failure(error);
      },
    );
  }

  Future<Result<GroupDto>> updateGroup({
    required String groupId,
    required String name,
    required String baseCurrency,
  }) async {
    final result = await ref.read(groupsRepositoryProvider).update(
          groupId: groupId,
          name: name,
          baseCurrency: baseCurrency,
        );
    return result.fold(
      onSuccess: (group) {
        _lastFetched = DateTime.now();
        state = state.whenData((groups) {
          final index = groups.indexWhere((item) => item.id == groupId);
          if (index == -1) {
            return groups;
          }
          final updated = List<GroupDto>.from(groups);
          updated[index] = group;
          return updated;
        });
        return Success(group);
      },
      onFailure: (error) => Failure(error),
    );
  }

  Future<Result<void>> deleteGroup(String groupId) async {
    final result = await ref.read(groupsRepositoryProvider).delete(groupId);
    return result.fold(
      onSuccess: (_) {
        _lastFetched = DateTime.now();
        state = state.whenData(
          (groups) => groups
              .where((group) => group.id != groupId)
              .toList(growable: false),
        );
        return const Success<void>(null);
      },
      onFailure: (error) => Failure(error),
    );
  }
}

final groupListControllerProvider =
    AsyncNotifierProvider<GroupListController, List<GroupDto>>(
  GroupListController.new,
);

/// 그룹 상세 정보 Provider
final groupDetailProvider = FutureProvider.autoDispose
    .family<GroupDto, String>((ref, groupId) async {
  final repository = ref.watch(groupsRepositoryProvider);
  return repository.fetchById(groupId).unwrap();
});

/// 그룹 멤버 목록 Provider
final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMemberDetail>, String>((ref, groupId) async {
  final membersRepository = ref.watch(membersRepositoryProvider);
  final usersRepository = ref.watch(usersRepositoryProvider);

  final members = await membersRepository.fetchByGroup(groupId).unwrap();
  if (members.isEmpty) {
    return const [];
  }
  final userIds = members.map((member) => member.userId).toSet().toList();
  final users = await usersRepository.fetchByIds(userIds).unwrap();
  final lookup = {
    for (final user in users) user.id: user,
  };
  return members
      .map(
        (member) => (member: member, user: lookup[member.userId]),
      )
      .toList(growable: false);
});

/// 그룹 지출 목록 Provider
final groupExpensesProvider = FutureProvider.autoDispose
    .family<List<ExpenseDto>, String>((ref, groupId) async {
  final repository = ref.watch(expensesRepositoryProvider);
  return repository.fetchByGroup(groupId).unwrap();
});
