import '../repositories/auth_repository.dart';

/// 사용자 프로필 동기화 UseCase
class SyncUserProfileUseCase {
  SyncUserProfileUseCase(this._repository);

  final AuthRepository _repository;

  /// 사용자 프로필 동기화
  /// 
  /// 현재 세션의 사용자 정보를 users 테이블에 동기화
  Future<void> call() => _repository.syncUserProfile();
}

