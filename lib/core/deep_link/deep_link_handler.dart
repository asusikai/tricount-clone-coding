import '../../features/home/home_page.dart';

/// 딥링크 처리 핸들러
///
/// 딥링크 파싱 및 분기를 담당하며, 실제 네비게이션과 메시지 표시는 콜백으로 처리합니다.
class DeepLinkHandler {
  DeepLinkHandler({
    required this.onNavigate,
    required this.onShowMessage,
    required this.onShowError,
  });

  /// 네비게이션 콜백
  final void Function(String route) onNavigate;

  /// 메시지 표시 콜백
  final void Function(String message) onShowMessage;

  /// 에러 표시 콜백
  final void Function(String message, {Object? error, StackTrace? stackTrace})
  onShowError;

  /// 딥링크 처리
  ///
  /// [uri] 처리할 딥링크 URI
  /// [isAuthenticated] 현재 인증 상태
  Future<void> handle(Uri uri, {required bool isAuthenticated}) async {
    try {
      // 그룹 초대 딥링크 처리
      if (isGroupInviteUri(uri)) {
        final inviteCode = parseInviteCode(uri);
        if (inviteCode == null || inviteCode.isEmpty) {
          onShowError(
            '유효하지 않은 초대 링크입니다.',
            error: StateError('Missing invite code: $uri'),
          );
          return;
        }

        if (!isAuthenticated) {
          onShowMessage('로그인 후 자동으로 그룹에 가입합니다.');
          onNavigate('/auth');
          return;
        }

        // 초대 코드는 InviteHandler에서 처리
        return;
      }

      // 홈 탭 딥링크 처리
      final tabFromLink = maybeParseHomeTabUri(uri);
      if (tabFromLink != null) {
        if (!isAuthenticated) {
          onShowMessage('로그인이 필요합니다. 먼저 로그인해주세요.');
          onNavigate('/auth');
          return;
        }
        onNavigate(tabFromLink.routePath);
        return;
      }

      // 지원하지 않는 링크
      final scheme = uri.scheme.toLowerCase();
      if (scheme == 'splitbills' || scheme == 'https') {
        onShowError(
          '지원하지 않는 링크입니다. 홈으로 이동합니다.',
          error: StateError('Unsupported link: $uri'),
        );
      }
    } on FormatException catch (error, stackTrace) {
      onShowError(
        '유효하지 않은 링크입니다. 홈으로 이동합니다.',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      onShowError(
        '링크 처리 중 오류가 발생했습니다. 홈으로 이동합니다.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// 홈 탭 URI 파싱
  HomeTab? maybeParseHomeTabUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();

    // https 스킴 지원
    if (scheme == 'https') {
      final candidates = <String?>[
        uri.queryParameters['tab'],
        if (uri.pathSegments.isNotEmpty) uri.pathSegments.first,
      ];

      for (final candidate in candidates) {
        final tab = HomeTabX.maybeFromName(candidate);
        if (tab != null) {
          return tab;
        }
      }
      return null;
    }

    if (scheme != 'splitbills') {
      return null;
    }

    final candidates = <String?>[
      uri.queryParameters['tab'],
      uri.host.isEmpty ? null : uri.host,
      if (uri.pathSegments.isNotEmpty) uri.pathSegments.first,
    ];

    for (final candidate in candidates) {
      final tab = HomeTabX.maybeFromName(candidate);
      if (tab != null) {
        return tab;
      }
    }

    return null;
  }

  /// 그룹 초대 URI 여부 확인
  bool isGroupInviteUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();

    // https 스킴 지원 (App Links / Universal Links)
    if (scheme == 'https') {
      final path = uri.path.toLowerCase();
      if (path.startsWith('/invite') || path.startsWith('/group/join')) {
        return true;
      }
      // 쿼리 파라미터로 초대 코드가 있는 경우
      if (uri.queryParameters.containsKey('code') ||
          uri.queryParameters.containsKey('invite')) {
        return true;
      }
    }

    if (scheme == 'splitbills') {
      if (uri.host.toLowerCase() == 'invite') {
        return true;
      }
      return uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.toLowerCase() == 'invite';
    }

    if (scheme == 'tricount') {
      final host = uri.host.toLowerCase();
      if (host == 'invite') {
        return true;
      }
      if (host == 'group') {
        return uri.pathSegments.isNotEmpty &&
            uri.pathSegments.first.toLowerCase() == 'join';
      }
      return uri.pathSegments.isNotEmpty &&
          uri.pathSegments.first.toLowerCase() == 'invite';
    }

    return false;
  }

  /// 초대 코드 파싱
  String? parseInviteCode(Uri uri) {
    final scheme = uri.scheme.toLowerCase();

    // 쿼리 파라미터에서 초대 코드 추출 (우선순위 1)
    final queryCode =
        uri.queryParameters['code']?.trim() ??
        uri.queryParameters['invite']?.trim();
    if (queryCode != null && queryCode.isNotEmpty) {
      return queryCode;
    }

    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList();

    // https 스킴 지원 (App Links / Universal Links)
    if (scheme == 'https') {
      // https://yourdomain.com/invite/<code>
      if (segments.isNotEmpty && segments.first.toLowerCase() == 'invite') {
        if (segments.length >= 2) {
          final candidate = segments[1].trim();
          if (candidate.isNotEmpty) {
            return candidate;
          }
        }
      }
      // https://yourdomain.com/group/join/<code>
      if (segments.length >= 3 &&
          segments[0].toLowerCase() == 'group' &&
          segments[1].toLowerCase() == 'join') {
        final candidate = segments[2].trim();
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
      // https://yourdomain.com/invite?code=<code> 형태는 이미 쿼리 파라미터에서 처리됨
    }

    if (scheme == 'splitbills') {
      // splitbills://invite/<code>
      if (uri.host.toLowerCase() == 'invite') {
        if (segments.isEmpty) {
          return null;
        }
        final candidate = segments.first.trim();
        return candidate.isNotEmpty ? candidate : null;
      }

      // splitbills://invite/<code> (경로 기반)
      if (segments.isNotEmpty && segments.first.toLowerCase() == 'invite') {
        if (segments.length < 2) {
          return null;
        }
        final candidate = segments[1].trim();
        return candidate.isNotEmpty ? candidate : null;
      }
    }

    if (scheme == 'tricount') {
      if (uri.host.toLowerCase() == 'invite') {
        if (segments.isEmpty) {
          return null;
        }
        final candidate = segments.first.trim();
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }

      if (segments.length >= 2 && segments.first.toLowerCase() == 'invite') {
        final candidate = segments[1].trim();
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }

      if (uri.host.toLowerCase() == 'group') {
        if (segments.length >= 2) {
          final candidate = segments[1].trim();
          if (candidate.isNotEmpty && candidate.toLowerCase() != 'join') {
            return candidate;
          }
        }
        if (segments.isNotEmpty) {
          final fallback = segments.last.trim();
          if (fallback.isNotEmpty && fallback.toLowerCase() != 'join') {
            return fallback;
          }
        }
      }
    }

    return null;
  }
}
