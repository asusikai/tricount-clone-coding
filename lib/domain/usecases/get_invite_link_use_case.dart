import '../repositories/group_repository.dart';

/// 그룹 초대 링크 생성 UseCase
class GetInviteLinkUseCase {
  GetInviteLinkUseCase(this._repository);

  final GroupRepository _repository;

  /// 그룹 초대 링크 생성
  /// 
  /// [groupId] 그룹 ID
  /// 
  /// 반환: 딥링크 URL
  Future<String> call(String groupId) =>
      _repository.getInviteLink(groupId);
}

