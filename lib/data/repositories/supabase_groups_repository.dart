import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/groups_repository.dart';
import 'supabase_mapper.dart';

class SupabaseGroupsRepository implements GroupsRepository {
  SupabaseGroupsRepository(this._client);

  final SupabaseClient _client;

  @override
  ResultFuture<List<GroupDto>> fetchByUser(String userId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('members')
            .select('groups(*)')
            .eq('user_id', userId) as List<dynamic>;
        return response
            .map<Map<String, dynamic>?>(
              (row) => (row as Map<String, dynamic>)['groups']
                  as Map<String, dynamic>?,
            )
            .whereType<Map<String, dynamic>>()
            .map(GroupDto.fromJson)
            .toList(growable: false);
      },
      context: '그룹 목록 조회 실패',
    );
  }

  @override
  ResultFuture<GroupDto> fetchById(String groupId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('groups')
            .select()
            .eq('id', groupId)
            .maybeSingle();
        if (response == null) {
          throw const NotFoundException('그룹을 찾을 수 없습니다.');
        }
        return GroupDto.fromJson(mapRow(response));
      },
      context: '그룹 상세 조회 실패',
    );
  }

  @override
  ResultFuture<List<GroupDto>> fetchByIds(List<String> groupIds) {
    if (groupIds.isEmpty) {
      return Future.value(const Success<List<GroupDto>>([]));
    }
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('groups')
            .select()
            .inFilter('id', groupIds);
        return mapRows(response)
            .map(GroupDto.fromJson)
            .toList(growable: false);
      },
      context: '그룹 다건 조회 실패',
    );
  }

  @override
  ResultFuture<GroupDto> create({
    required String ownerId,
    required String name,
    required String baseCurrency,
  }) {
    return ErrorHandler.guardAsync(
      () async {
        final payload = {
          'name': name,
          'base_currency': baseCurrency,
          'owner_id': ownerId,
        };
        final response = await _client
            .from('groups')
            .insert(payload)
            .select()
            .single();

        final group = GroupDto.fromJson(mapRow(response));

        await _client.from('members').insert({
          'group_id': group.id,
          'user_id': ownerId,
          'role': 'owner',
        });

        return group;
      },
      context: '그룹 생성 실패',
    );
  }

  @override
  ResultFuture<GroupDto> joinByInvite({
    required String inviteCode,
    required String userId,
  }) {
    return ErrorHandler.guardAsync(
      () async {
        final rpcGroupId = await _tryJoinGroupViaRpc(inviteCode);
        final groupId =
            rpcGroupId ?? await _joinGroupFallback(inviteCode, userId);
        return (await fetchById(groupId)).requireValue;
      },
      context: '그룹 초대 코드 가입 실패',
    );
  }

  @override
  ResultFuture<void> delete(String groupId) {
    return ErrorHandler.guardAsync(
      () async {
        await _client.from('members').delete().eq('group_id', groupId);
        await _client.from('groups').delete().eq('id', groupId);
      },
      context: '그룹 삭제 실패',
    );
  }

  @override
  ResultFuture<String> getInviteLink(String groupId) {
    return ErrorHandler.guardAsync(
      () async {
        final response = await _client
            .from('groups')
            .select('invite_code')
            .eq('id', groupId)
            .maybeSingle();
        if (response == null) {
          throw const NotFoundException('그룹을 찾을 수 없습니다.');
        }
        final inviteCode = response['invite_code'] as String?;
        if (inviteCode == null || inviteCode.isEmpty) {
          throw const ValidationException('유효하지 않은 초대 코드입니다.');
        }
        return 'splitbills://invite?code=$inviteCode';
      },
      context: '초대 링크 생성 실패',
    );
  }

  Future<String?> _tryJoinGroupViaRpc(String inviteCode) async {
    try {
      final response = await _client.rpc(
        'rpc_create_invite',
        params: {'code': inviteCode},
      );
      return _extractGroupIdFromRpc(response);
    } catch (_) {
      return null;
    }
  }

  Future<String> _joinGroupFallback(String inviteCode, String userId) async {
    final groupResponse = await _client
        .from('groups')
        .select()
        .eq('invite_code', inviteCode)
        .maybeSingle();

    if (groupResponse == null) {
      throw const ValidationException('유효하지 않은 초대 코드입니다.');
    }
    final group = GroupDto.fromJson(mapRow(groupResponse));

    final existingMember = await _client
        .from('members')
        .select()
        .eq('group_id', group.id)
        .eq('user_id', userId)
        .maybeSingle();
    if (existingMember != null) {
      return group.id;
    }

    await _client.from('members').insert({
      'group_id': group.id,
      'user_id': userId,
    });

    return group.id;
  }

  String? _extractGroupIdFromRpc(dynamic response) {
    if (response == null) {
      return null;
    }
    if (response is String && response.isNotEmpty) {
      return response;
    }
    if (response is Map<String, dynamic>) {
      final groupId = response['group_id'] ?? response['id'];
      if (groupId is String && groupId.isNotEmpty) {
        return groupId;
      }
    }
    if (response is Map) {
      final map = Map<String, dynamic>.from(response as Map);
      final groupId = map['group_id'] ?? map['id'];
      if (groupId is String && groupId.isNotEmpty) {
        return groupId;
      }
    }
    if (response is List && response.isNotEmpty) {
      return _extractGroupIdFromRpc(response.first);
    }
    if (response is num) {
      return response.toString();
    }
    return null;
  }
}
