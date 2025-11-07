import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class GroupService {
  GroupService(this._client);

  final SupabaseClient _client;
  final _uuid = const Uuid();

  /// 그룹 생성
  /// 
  /// [name] 그룹 이름
  /// [baseCurrency] 기본 통화 (예: 'KRW', 'USD')
  /// 
  /// 반환: 생성된 그룹 ID
  Future<String> createGroup({
    required String name,
    required String baseCurrency,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 초대 코드 생성 (UUID)
      final inviteCode = _uuid.v4();

      // 그룹 생성
      final groupResponse = await _client
          .from('groups')
          .insert({
            'name': name,
            'base_currency': baseCurrency,
            'invite_code': inviteCode,
            'owner_id': user.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final groupId = groupResponse['id'] as String;

      // 생성자를 멤버로 추가
      await _client.from('members').insert({
        'user_id': user.id,
        'group_id': groupId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      debugPrint('그룹 생성 성공: $groupId (초대 코드: $inviteCode)');
      return groupId;
    } catch (error, stackTrace) {
      debugPrint('그룹 생성 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// 초대 코드로 그룹 가입
  /// 
  /// [inviteCode] 초대 코드 (UUID)
  /// 
  /// 반환: 가입한 그룹 ID
  Future<String> joinGroupByInviteCode(String inviteCode) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 우선 RPC(rpc_create_invite)를 시도해 자동 가입 처리
      final rpcGroupId = await _tryJoinGroupViaRpc(inviteCode);
      if (rpcGroupId != null && rpcGroupId.isNotEmpty) {
        debugPrint('RPC 기반 그룹 가입 성공: $rpcGroupId');
        return rpcGroupId;
      }

      // 초대 코드로 그룹 찾기
      final groupResponse = await _client
          .from('groups')
          .select()
          .eq('invite_code', inviteCode)
          .maybeSingle();

      if (groupResponse == null) {
        throw Exception('유효하지 않은 초대 코드입니다.');
      }

      final groupId = groupResponse['id'] as String;

      // 이미 멤버인지 확인
      final existingMember = await _client
          .from('members')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingMember != null) {
        debugPrint('이미 그룹 멤버입니다: $groupId');
        return groupId;
      }

      // 멤버로 추가
      await _client.from('members').insert({
        'user_id': user.id,
        'group_id': groupId,
        'joined_at': DateTime.now().toIso8601String(),
      });

      debugPrint('그룹 가입 성공: $groupId');
      return groupId;
    } catch (error, stackTrace) {
      debugPrint('그룹 가입 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// 사용자가 가입한 그룹 목록 조회
  Future<List<Map<String, dynamic>>> getUserGroups() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return [];
      }

      // 사용자가 멤버인 그룹 조회
      final response = await _client
          .from('members')
          .select('''
            group_id,
            groups (
              id,
              name,
              base_currency,
              invite_code,
              created_at
            )
          ''')
          .eq('user_id', user.id);

      final groups = <Map<String, dynamic>>[];
      for (final member in response) {
        final groupData = member['groups'] as Map<String, dynamic>?;
        if (groupData != null) {
          groups.add(groupData);
        }
      }

      return groups;
    } catch (error, stackTrace) {
      debugPrint('그룹 목록 조회 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      return [];
    }
  }

  /// 그룹 멤버 목록 조회 (사용자 정보 포함)
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      final response = await _client
          .from('members')
          .select('''
            user_id,
            joined_at,
            users (
              id,
              name,
              nickname,
              email
            )
          ''')
          .eq('group_id', groupId);

      return response
          .map<Map<String, dynamic>>((member) {
            final user = member['users'] as Map<String, dynamic>?;
            return {
              'user_id': member['user_id'],
              'joined_at': member['joined_at'],
              if (user != null) ...user,
            };
          })
          .toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('그룹 멤버 조회 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// 그룹 상세 정보 조회
  Future<Map<String, dynamic>> getGroupDetail(String groupId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      final response = await _client
          .from('groups')
          .select('id, name, base_currency, invite_code, owner_id, created_at')
          .eq('id', groupId)
          .maybeSingle();

      if (response == null) {
        throw StateError('그룹을 찾을 수 없습니다.');
      }

      return response;
    } catch (error, stackTrace) {
      debugPrint('그룹 상세 조회 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// 그룹 삭제 (소유자만 가능)
  Future<void> deleteGroup(String groupId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 그룹 소유자 확인 (첫 번째 멤버가 소유자로 간주)
      final groupResponse = await _client
          .from('groups')
          .select('id')
          .eq('id', groupId)
          .maybeSingle();

      if (groupResponse == null) {
        throw Exception('그룹을 찾을 수 없습니다.');
      }

      // 멤버십 삭제
      await _client.from('members').delete().eq('group_id', groupId);

      // 그룹 삭제
      await _client.from('groups').delete().eq('id', groupId);

      debugPrint('그룹 삭제 성공: $groupId');
    } catch (error, stackTrace) {
      debugPrint('그룹 삭제 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// 그룹 초대 링크 생성
  /// 
  /// [groupId] 그룹 ID
  /// 
  /// 반환: 딥링크 URL
  Future<String> getInviteLink(String groupId) async {
    try {
      final groupResponse = await _client
          .from('groups')
          .select('invite_code')
          .eq('id', groupId)
          .maybeSingle();

      if (groupResponse == null) {
        throw Exception('그룹을 찾을 수 없습니다.');
      }

      final inviteCode = groupResponse['invite_code'] as String;
      return 'splitbills://invite?code=$inviteCode';
    } catch (error, stackTrace) {
      debugPrint('초대 링크 생성 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<String?> _tryJoinGroupViaRpc(String inviteCode) async {
    try {
      final response = await _client.rpc(
        'rpc_create_invite',
        params: {'code': inviteCode},
      );
      return _extractGroupIdFromRpc(response);
    } catch (error, stackTrace) {
      debugPrint('rpc_create_invite 실패: $error');
      debugPrint('스택 트레이스: $stackTrace');
      return null;
    }
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
    if (response is List && response.isNotEmpty) {
      return _extractGroupIdFromRpc(response.first);
    }
    if (response is num) {
      return response.toString();
    }
    return null;
  }
}

