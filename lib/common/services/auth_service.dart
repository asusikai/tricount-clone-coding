import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// 인증 관련 서비스 클래스
/// 
/// 내부적으로 AuthRepository를 사용하여 데이터 접근을 처리합니다.
class AuthService {
  AuthService(this._repository);

  final AuthRepository _repository;

  /// SupabaseClient를 직접 받는 생성자 (하위 호환성)
  AuthService.fromClient(SupabaseClient client)
      : _repository = AuthRepositoryImpl(client);

  // 로그인 시작 시간 추적 (static으로 전역 공유)
  static DateTime? get lastSignInAttemptTime =>
      AuthRepositoryImpl.lastSignInAttemptTime;

  static void clearSignInAttemptTime() =>
      AuthRepositoryImpl.clearSignInAttemptTime();

  // 인증 에러 메시지 저장 (static으로 전역 공유)
  static String? get lastAuthError => AuthRepositoryImpl.lastAuthError;

  static void setAuthError(String? error) =>
      AuthRepositoryImpl.setAuthError(error);

  static void clearAuthError() => AuthRepositoryImpl.clearAuthError();

  // OAuth 플로우 상태 저장 (provider별로 관리)
  static Uri prepareCallbackUri(Uri uri, String providerName) =>
      AuthRepositoryImpl.prepareCallbackUri(uri, providerName);

  static void clearFlowState(String providerName) =>
      AuthRepositoryImpl.clearFlowState(providerName);

  Future<void> signInWithProvider(OAuthProvider provider) =>
      _repository.signInWithProvider(provider);

  Future<void> signOut() => _repository.signOut();

  Future<void> syncUserProfile() => _repository.syncUserProfile();
}
