import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

/// OAuth 제공자로 로그인 UseCase
class SignInWithProviderUseCase {
  SignInWithProviderUseCase(this._repository);

  final AuthRepository _repository;

  /// OAuth 제공자로 로그인 시작
  /// 
  /// [provider] OAuth 제공자 (Google, Apple, Kakao 등)
  Future<void> call(OAuthProvider provider) =>
      _repository.signInWithProvider(provider);
}

