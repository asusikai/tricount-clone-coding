import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/group_service.dart';
import '../../features/home/home_page.dart';

/// 초대 코드 처리 핸들러
/// 
/// 그룹 초대 코드를 처리하고 가입을 수행합니다.
class InviteHandler {
  InviteHandler({
    required this.onNavigate,
    required this.onShowMessage,
    required this.onShowError,
  });

  /// 네비게이션 콜백
  final void Function(String route) onNavigate;

  /// 메시지 표시 콜백
  final void Function(String message) onShowMessage;

  /// 에러 표시 콜백 (재시도 가능 여부 포함)
  final void Function(
    String message, {
    String? inviteCode,
  }) onShowError;

  final List<String> _pendingInviteCodes = <String>[];
  final Set<String> _processingInviteCodes = <String>{};
  final Set<String> _completedInviteCodes = <String>{};

  /// 초대 코드 큐에 추가
  void queueInviteCode(String inviteCode) {
    if (_pendingInviteCodes.contains(inviteCode)) {
      return;
    }
    _pendingInviteCodes.add(inviteCode);
  }

  /// 대기 중인 초대 코드 처리
  Future<void> processPendingInvites() async {
    if (_pendingInviteCodes.isEmpty) {
      return;
    }
    final queued = List<String>.from(_pendingInviteCodes);
    _pendingInviteCodes.clear();
    for (final code in queued) {
      await processInviteCode(code);
    }
  }

  /// 초대 코드 처리
  /// 
  /// [inviteCode] 처리할 초대 코드
  Future<void> processInviteCode(String inviteCode) async {
    if (_completedInviteCodes.contains(inviteCode)) {
      debugPrint('이미 완료된 초대 코드: $inviteCode');
      onShowMessage('이미 처리된 초대 링크입니다.');
      return;
    }
    if (_processingInviteCodes.contains(inviteCode)) {
      debugPrint('이미 처리 중인 초대 코드: $inviteCode');
      return;
    }

    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      queueInviteCode(inviteCode);
      return;
    }

    _processingInviteCodes.add(inviteCode);
    try {
      final groupService = GroupService.fromClient(client);
      final groupId = await groupService.joinGroupByInviteCode(inviteCode);
      debugPrint('그룹 가입 성공: $groupId');
      _completedInviteCodes.add(inviteCode);
      onShowMessage('그룹에 가입되었습니다.');
      final route = groupId.isEmpty
          ? HomeTab.groups.routePath
          : '/groups/${Uri.encodeComponent(groupId)}';
      onNavigate(route);
    } catch (error, stackTrace) {
      debugPrint('그룹 초대 처리 실패 ($inviteCode): $error');
      debugPrint('스택 트레이스: $stackTrace');
      final friendlyMessage = _describeInviteError(error);
      final retryable = _isRetryableInviteError(error);
      if (retryable) {
        queueInviteCode(inviteCode);
      }
      onShowError(
        friendlyMessage,
        inviteCode: retryable ? inviteCode : null,
      );
    } finally {
      _processingInviteCodes.remove(inviteCode);
    }
  }

  /// 초대 코드 재시도
  void retryInvite(String inviteCode) {
    _pendingInviteCodes.remove(inviteCode);
    processInviteCode(inviteCode);
  }

  /// 초대 코드가 이미 완료되었는지 확인
  bool isCompleted(String inviteCode) => _completedInviteCodes.contains(inviteCode);

  String _describeInviteError(Object error) {
    final message = error.toString();
    final lower = message.toLowerCase();
    if (lower.contains('유효하지') || lower.contains('invalid')) {
      return '초대 코드가 유효하지 않거나 만료되었습니다.';
    }
    if (lower.contains('만료') || lower.contains('expired')) {
      return '초대 코드가 만료되었습니다. 그룹 관리자에게 새 링크를 요청해주세요.';
    }
    if (lower.contains('권한') ||
        lower.contains('permission') ||
        lower.contains('forbidden')) {
      return '이 초대에 접근할 권한이 없습니다.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timeout')) {
      return '네트워크 연결 문제로 가입에 실패했습니다. 잠시 후 다시 시도해주세요.';
    }
    return '그룹 가입에 실패했습니다. 잠시 후 다시 시도해주세요.';
  }

  bool _isRetryableInviteError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('유효하지') ||
        lower.contains('invalid') ||
        lower.contains('만료') ||
        lower.contains('expired')) {
      return false;
    }
    return true;
  }
}

