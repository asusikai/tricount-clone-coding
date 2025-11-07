import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/environment.dart';
import '../../core/errors/errors.dart';

class AuthService {
  AuthService(this._client);

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

  Future<void> syncUserProfile() async {
    final session = _client.auth.currentSession;
    if (session == null) return;

    final user = session.user;
    final name = _extractName(user.userMetadata);
    final provider = _extractProvider(session);

    final payload =
        <String, dynamic>{
          'id': user.id,
          'email': user.email,
          'name': name,
          'provider': provider,
        }..removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty),
        );

    if (payload.isEmpty) return;

    try {
      await _client.from('users').upsert(payload, onConflict: 'id');
    } catch (error, stackTrace) {
      throw ErrorHandler.handleAndLog(
        error,
        stackTrace: stackTrace,
        context: '사용자 프로필 동기화 실패',
      );
    }
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
      'nickname',
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
}
