import '../repositories/group_repository.dart';

/// 그룹 삭제 UseCase
class DeleteGroupUseCase {
  DeleteGroupUseCase(this._repository);

  final GroupRepository _repository;

  /// 그룹 삭제 (소유자만 가능)
  /// 
  /// [groupId] 그룹 ID
  Future<void> call(String groupId) =>
      _repository.deleteGroup(groupId);
}

