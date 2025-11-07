import '../repositories/group_repository.dart';

/// 그룹 멤버 목록 조회 UseCase
class GetGroupMembersUseCase {
  GetGroupMembersUseCase(this._repository);

  final GroupRepository _repository;

  /// 그룹 멤버 목록 조회 (사용자 정보 포함)
  /// 
  /// [groupId] 그룹 ID
  Future<List<Map<String, dynamic>>> call(String groupId) =>
      _repository.getGroupMembers(groupId);
}

