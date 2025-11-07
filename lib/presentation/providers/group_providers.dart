import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/group_service.dart';

/// 그룹 서비스 Provider
final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService.fromClient(Supabase.instance.client);
});

/// 사용자의 그룹 목록 Provider
final userGroupsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getUserGroups();
});

/// 그룹 상세 정보 Provider
final groupDetailProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, groupId) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getGroupDetail(groupId);
});

/// 그룹 멤버 목록 Provider
final groupMembersProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, groupId) async {
  final groupService = ref.read(groupServiceProvider);
  return groupService.getGroupMembers(groupId);
});

