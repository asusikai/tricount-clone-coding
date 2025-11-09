import '../../core/errors/errors.dart';
import '../models/models.dart';

abstract class UsersRepository {
  ResultFuture<UserDto> fetchById(String userId);

  ResultFuture<List<UserDto>> fetchByIds(List<String> userIds);

  ResultFuture<UserDto> upsert(UserDto user);
}
