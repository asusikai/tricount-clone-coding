import 'package:supabase_flutter/supabase_flutter.dart';

/// 인증 관련 데이터 접근 인터페이스
abstract class AuthRepository {
  /// OAuth 제공자로 로그인 시작
  /// 
  /// [provider] OAuth 제공자 (Google, Apple, Kakao 등)
  Future<void> signInWithProvider(OAuthProvider provider);

  /// 로그아웃
  Future<void> signOut();

  /// 사용자 프로필 동기화
  /// 
  /// 현재 세션의 사용자 정보를 users 테이블에 동기화
  Future<void> syncUserProfile();
}

