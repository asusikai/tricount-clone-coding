import '../repositories/group_repository.dart';

/// 사용자 그룹 목록 조회 UseCase
class GetUserGroupsUseCase {
  GetUserGroupsUseCase(this._repository);

  final GroupRepository _repository;

  /// 사용자가 가입한 그룹 목록 조회
  Future<List<Map<String, dynamic>>> call() =>
      _repository.getUserGroups();
}

