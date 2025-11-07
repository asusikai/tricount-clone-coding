import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  const ProfileService(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (error, stackTrace) {
      debugPrint('프로필 조회 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateName(String userId, String name) async {
    try {
      await _client
          .from('users')
          .update({'name': name.trim()})
          .eq('id', userId);
    } catch (error, stackTrace) {
      debugPrint('프로필 이름 업데이트 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> updateNickname(String userId, String nickname) async {
    try {
      await _client
          .from('users')
          .update({'nickname': nickname.trim()})
          .eq('id', userId);
    } catch (error, stackTrace) {
      debugPrint('닉네임 업데이트 실패: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
