import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/members_repository.dart';
import 'supabase_mapper.dart';

class SupabaseMembersRepository implements MembersRepository {
  SupabaseMembersRepository(this._client);

  final SupabaseClient _client;

  @override
  ResultFuture<List<MemberDto>> fetchByGroup(String groupId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('members')
            .select()
            .eq('group_id', groupId);
        return mapRows(response).map(MemberDto.fromJson).toList(growable: false);
      },
      context: '그룹 멤버 조회 실패',
    );
  }

  @override
  ResultFuture<MemberDto> addMember({
    required String groupId,
    required String userId,
    MembershipRole role = MembershipRole.member,
  }) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('members')
            .insert({
              'group_id': groupId,
              'user_id': userId,
              'role': role.dbValue,
            })
            .select()
            .single();
        return MemberDto.fromJson(mapRow(response));
      },
      context: '멤버 추가 실패',
    );
  }

  @override
  ResultFuture<void> removeMember(String memberId) {
    return ErrorHandler.guardAsync(
      () async {
        await _client.from('members').delete().eq('id', memberId);
      },
      context: '멤버 삭제 실패',
    );
  }
}
