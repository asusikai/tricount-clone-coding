import '../repositories/auth_repository.dart';

/// 로그아웃 UseCase
class SignOutUseCase {
  SignOutUseCase(this._repository);

  final AuthRepository _repository;

  /// 로그아웃
  Future<void> call() => _repository.signOut();
}

