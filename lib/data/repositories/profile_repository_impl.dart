import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/errors.dart';
import '../../domain/repositories/profile_repository.dart';

/// Supabase 기반 ProfileRepository 구현체
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (error, stackTrace) {
      throw ErrorHandler.handleAndLog(
        error,
        stackTrace: stackTrace,
        context: '프로필 조회 실패',
      );
    }
  }

  @override
  Future<void> updateName(String userId, String name) async {
    try {
      await _client
          .from('users')
          .update({'name': name.trim()})
          .eq('id', userId);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleAndLog(
        error,
        stackTrace: stackTrace,
        context: '프로필 이름 업데이트 실패',
      );
    }
  }

  @override
  Future<void> updateNickname(String userId, String nickname) async {
    try {
      await _client
          .from('users')
          .update({'nickname': nickname.trim()})
          .eq('id', userId);
    } catch (error, stackTrace) {
      throw ErrorHandler.handleAndLog(
        error,
        stackTrace: stackTrace,
        context: '닉네임 업데이트 실패',
      );
    }
  }
}

