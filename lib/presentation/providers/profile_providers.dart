import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/profile_service.dart';

/// 프로필 서비스 Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService.fromClient(Supabase.instance.client);
});

