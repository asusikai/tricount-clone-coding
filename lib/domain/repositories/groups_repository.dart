import '../../core/errors/errors.dart';
import '../models/models.dart';

abstract class GroupsRepository {
  ResultFuture<List<GroupDto>> fetchByUser(String userId);

  ResultFuture<GroupDto> fetchById(String groupId);

  ResultFuture<List<GroupDto>> fetchByIds(List<String> groupIds);

  ResultFuture<GroupDto> create({
    required String ownerId,
    required String name,
    required String baseCurrency,
  });

  ResultFuture<GroupDto> joinByInvite({
    required String inviteCode,
    required String userId,
  });

  ResultFuture<void> delete(String groupId);

  ResultFuture<String> getInviteLink(String groupId);
}
