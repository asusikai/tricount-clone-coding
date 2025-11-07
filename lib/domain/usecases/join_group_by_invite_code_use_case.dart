import '../repositories/group_repository.dart';

/// 초대 코드로 그룹 가입 UseCase
class JoinGroupByInviteCodeUseCase {
  JoinGroupByInviteCodeUseCase(this._repository);

  final GroupRepository _repository;

  /// 초대 코드로 그룹 가입
  /// 
  /// [inviteCode] 초대 코드 (UUID)
  /// 
  /// 반환: 가입한 그룹 ID
  Future<String> call(String inviteCode) =>
      _repository.joinGroupByInviteCode(inviteCode);
}

