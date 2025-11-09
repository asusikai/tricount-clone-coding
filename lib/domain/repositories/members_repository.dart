import '../../core/errors/errors.dart';
import '../models/models.dart';

abstract class MembersRepository {
  ResultFuture<List<MemberDto>> fetchByGroup(String groupId);

  ResultFuture<MemberDto> addMember({
    required String groupId,
    required String userId,
    MembershipRole role,
  });

  ResultFuture<void> removeMember(String memberId);
}
