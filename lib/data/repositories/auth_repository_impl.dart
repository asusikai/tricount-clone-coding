import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/environment.dart';
import '../../core/errors/errors.dart';
import '../../domain/repositories/auth_repository.dart';

/// Supabase 기반 AuthRepository 구현체
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._client);

  final SupabaseClient _client;

  // 로그인 시작 시간 추적 (static으로 전역 공유)
  static DateTime? _lastSignInAttemptTime;

  static DateTime? get lastSignInAttemptTime => _lastSignInAttemptTime;

  static void clearSignInAttemptTime() {
    _lastSignInAttemptTime = null;
  }

  // 인증 에러 메시지 저장 (static으로 전역 공유)
  static String? _lastAuthError;

  static String? get lastAuthError => _lastAuthError;

  static void setAuthError(String? error) {
    _lastAuthError = error;
  }

  static void clearAuthError() {
    _lastAuthError = null;
  }

  // OAuth 플로우 상태 저장 (provider별로 관리)
  static final Map<String, Map<String, String>> _lastFlowParams = {};

  static Uri prepareCallbackUri(Uri uri, String providerName) {
    final providerKey = providerName.toLowerCase();
    final savedParams = _lastFlowParams[providerKey];

    if (savedParams == null || savedParams.isEmpty) {
      return uri;
    }

    final hasState =
        uri.queryParameters.containsKey('state') ||
        uri.queryParameters.containsKey('flow_state');

    if (hasState) {
      return uri;
    }

    final newQuery = Map<String, String>.from(uri.queryParameters);
    for (final entry in savedParams.entries) {
      if (entry.key == 'state' || entry.key == 'flow_state') {
        newQuery.putIfAbsent(entry.key, () => entry.value);
      }
    }

    if (newQuery.length == uri.queryParameters.length) {
      return uri;
    }

    debugPrint('누락된 flow state 보강 ($providerKey): ${savedParams.toString()}');
    return uri.replace(queryParameters: newQuery);
  }

  static void clearFlowState(String providerName) {
    _lastFlowParams.remove(providerName.toLowerCase());
  }

  @override
  Future<void> signInWithProvider(OAuthProvider provider) async {
    final redirectUri = _buildRedirectUri(provider);

    try {
      // 이전 로그인 시도가 있었는지 확인
      final lastAttempt = _lastSignInAttemptTime;
      if (lastAttempt != null) {
        final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
        // 로그아웃 후 바로 로그인하는 경우를 대비해 충분히 대기
        // 로그아웃 시 1초 대기 + 여기서 추가 대기 = 총 2초 이상
        if (timeSinceLastAttempt.inMilliseconds < 2000) {
          final waitTime = 2000 - timeSinceLastAttempt.inMilliseconds;
          if (waitTime > 0) {
            debugPrint('이전 로그인 시도 후 ${waitTime}ms 대기 중... (PKCE 상태 정리 대기)');
            await Future.delayed(Duration(milliseconds: waitTime));
          }
        }
      } else {
        // 로그인 시작 시간이 없으면 로그아웃 직후일 수 있으므로 충분한 대기
        debugPrint('로그인 시작 시간 없음 - PKCE 상태 정리 대기 중...');
        await Future.delayed(const Duration(milliseconds: 1000));
      }

      // 로그인 시작 시간 기록
      _lastSignInAttemptTime = DateTime.now();
      debugPrint('로그인 시작: ${provider.name} at $_lastSignInAttemptTime');

      // 이전 플로우 상태 정리 (새로운 로그인 시도 전)
      clearFlowState(provider.name);

      // signInWithOAuth는 Future<bool>을 반환합니다
      // PKCE 플로우 상태는 Supabase SDK가 자동으로 관리합니다
      final success = await _client.auth.signInWithOAuth(
        provider,
        redirectTo: redirectUri,
      );

      if (!success) {
        throw const UnknownException('OAuth 로그인 시작에 실패했습니다.');
      }

      debugPrint('OAuth 로그인 시작 성공 (${provider.name})');
    } catch (error, stackTrace) {
      // 로그인 실패 시 시간 초기화 및 상태 제거
      _lastSignInAttemptTime = null;
      clearFlowState(provider.name);
      throw ErrorHandler.handleAndLog(
        error,
        stackTrace: stackTrace,
        context: 'OAuth 로그인 실패 (${provider.name})',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // 로그아웃 수행 전에 현재 시간 기록 (다음 로그인 시 대기 시간 계산용)
      // _lastSignInAttemptTime을 null로 설정하지 않음 - 로그인 시 대기 시간 계산에 사용
      _lastFlowParams.clear();

      // 로그아웃 수행
      await _client.auth.signOut();

      // PKCE 플로우 상태가 완전히 정리되도록 충분한 지연
      // Supabase SDK가 secure storage의 PKCE code verifier를 정리하는데 시간이 필요함
      await Future.delayed(const Duration(milliseconds: 1000));

      debugPrint('로그아웃 완료 및 PKCE 상태 정리됨');
    } catch (error, stackTrace) {
      // 에러가 발생해도 플로우 상태는 초기화
      _lastFlowParams.clear();
      throw ErrorHandler.handleAndLog(
        error,
        stackTrace: stackTrace,
        context: '로그아웃 실패',
      );
    }
  }

  @override
  Future<void> syncUserProfile() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    await upsertFromAuthSession(session);
  }

  /// Auth 세션에서 사용자 정보를 추출하여 users 테이블에 upsert
  ///
  /// [session] Supabase Auth 세션
  /// [maxRetries] 최대 재시도 횟수 (기본값: 3)
  ///
  /// 반환: upsert 성공 여부
  Future<bool> upsertFromAuthSession(
    Session session, {
    int maxRetries = 3,
  }) async {
    final user = session.user;
    final now = DateTime.now().toIso8601String();

    // 필수 필드 추출
    final name = _extractName(user.userMetadata);
    final provider = _extractProvider(session);
    final nickname = _extractNickname(user.userMetadata);
    final avatarUrl = _extractAvatarUrl(user.userMetadata, user);

    // upsert 페이로드 구성
    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email ?? '',
      'updated_at': now,
    };

    // 선택적 필드 추가 (null이 아닌 경우만)
    if (name != null && name.isNotEmpty) {
      payload['name'] = name;
    }
    if (nickname != null && nickname.isNotEmpty) {
      payload['nickname'] = nickname;
    }
    if (provider != null && provider.isNotEmpty) {
      payload['provider'] = provider;
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      payload['avatar_url'] = avatarUrl;
    }

    // created_at은 새 사용자인 경우에만 설정 (upsert의 onConflict로 처리)
    // Supabase의 upsert는 기존 레코드가 있으면 created_at을 유지하고,
    // 없으면 새로 생성하므로 별도 처리 불필요

    // 재시도 로직
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        await _client.from('users').upsert(payload, onConflict: 'id');
        debugPrint('사용자 프로필 upsert 성공 (시도 ${attempt + 1})');
        return true;
      } catch (error, stackTrace) {
        attempt++;
        debugPrint('사용자 프로필 upsert 실패 (시도 $attempt/$maxRetries): $error');

        if (attempt >= maxRetries) {
          // 최대 재시도 횟수 초과
          ErrorHandler.handleAndLog(
            error,
            stackTrace: stackTrace,
            context: '사용자 프로필 동기화 실패 (최대 재시도 횟수 초과)',
          );
          return false;
        }

        // 재시도 전 대기 (지수 백오프)
        final delayMs = 500 * attempt; // 500ms, 1000ms, 1500ms...
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }

    return false;
  }

  String _buildRedirectUri(OAuthProvider provider) {
    final providerName = provider.name.toLowerCase();
    return Environment.buildSupabaseRedirectUri(providerName);
  }

  String? _extractProvider(Session session) {
    final fromMetadata = session.user.appMetadata['provider'];
    if (fromMetadata is String && fromMetadata.isNotEmpty) {
      return fromMetadata;
    }

    final identities = session.user.identities;
    if (identities != null && identities.isNotEmpty) {
      final identity = identities.first;
      if (identity.provider.isNotEmpty == true) {
        return identity.provider;
      }
    }

    return null;
  }

  String? _extractName(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;

    const preferredKeys = [
      'full_name',
      'name',
      'display_name',
      'preferred_username',
    ];

    for (final key in preferredKeys) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  String? _extractNickname(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;

    const nicknameKeys = ['nickname', 'preferred_username', 'username'];

    for (final key in nicknameKeys) {
      final value = metadata[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  String? _extractAvatarUrl(Map<String, dynamic>? metadata, User user) {
    // userMetadata에서 avatar_url 추출
    if (metadata != null) {
      final avatarUrl = metadata['avatar_url'] ?? metadata['picture'];
      if (avatarUrl is String && avatarUrl.trim().isNotEmpty) {
        return avatarUrl.trim();
      }
    }

    // user 객체의 avatar_url 확인
    final userAvatarUrl =
        user.userMetadata?['avatar_url'] ?? user.userMetadata?['picture'];
    if (userAvatarUrl is String && userAvatarUrl.trim().isNotEmpty) {
      return userAvatarUrl.trim();
    }

    return null;
  }
}
