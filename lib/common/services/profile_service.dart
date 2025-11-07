import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/profile_repository.dart';

/// 프로필 관련 서비스 클래스
/// 
/// 내부적으로 ProfileRepository를 사용하여 데이터 접근을 처리합니다.
class ProfileService {
  ProfileService(this._repository);

  final ProfileRepository _repository;

  /// SupabaseClient를 직접 받는 생성자 (하위 호환성)
  ProfileService.fromClient(SupabaseClient client)
      : _repository = ProfileRepositoryImpl(client);

  Future<Map<String, dynamic>?> fetchProfile(String userId) =>
      _repository.fetchProfile(userId);

  Future<void> updateName(String userId, String name) =>
      _repository.updateName(userId, name);

  Future<void> updateNickname(String userId, String nickname) =>
      _repository.updateNickname(userId, nickname);
}
