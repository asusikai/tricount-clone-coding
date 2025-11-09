import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/users_repository.dart';
import 'supabase_mapper.dart';

class SupabaseUsersRepository implements UsersRepository {
  SupabaseUsersRepository(this._client);

  final SupabaseClient _client;

  @override
  ResultFuture<UserDto> fetchById(String userId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (response == null) {
          throw const NotFoundException('사용자를 찾을 수 없습니다.');
        }
        return UserDto.fromJson(mapRow(response));
      },
      context: '사용자 조회 실패',
    );
  }

  @override
  ResultFuture<List<UserDto>> fetchByIds(List<String> userIds) {
    if (userIds.isEmpty) {
      return Future.value(const Success<List<UserDto>>([]));
    }
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('users')
            .select()
            .inFilter('id', userIds);
        return mapRows(response)
            .map(UserDto.fromJson)
            .toList(growable: false);
      },
      context: '사용자 다건 조회 실패',
    );
  }

  @override
  ResultFuture<UserDto> upsert(UserDto user) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('users')
            .upsert(user.toJson())
            .select()
            .single();
        return UserDto.fromJson(mapRow(response));
      },
      context: '사용자 저장 실패',
    );
  }
}
