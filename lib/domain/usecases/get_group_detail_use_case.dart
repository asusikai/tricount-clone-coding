import '../repositories/group_repository.dart';

/// 그룹 상세 정보 조회 UseCase
class GetGroupDetailUseCase {
  GetGroupDetailUseCase(this._repository);

  final GroupRepository _repository;

  /// 그룹 상세 정보 조회
  /// 
  /// [groupId] 그룹 ID
  Future<Map<String, dynamic>> call(String groupId) =>
      _repository.getGroupDetail(groupId);
}

