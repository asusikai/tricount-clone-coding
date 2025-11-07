import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/models/payment_request.dart';
import '../../common/services/request_service.dart';

/// 요청 서비스 Provider
final requestServiceProvider = Provider<RequestService>((ref) {
  return RequestService.fromClient(Supabase.instance.client);
});

/// 요청 목록 Provider
final requestListProvider = FutureProvider.autoDispose
    .family<List<PaymentRequest>, PaymentRequestStatus?>((ref, status) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return <PaymentRequest>[];
  }

  final service = ref.watch(requestServiceProvider);
  return service.fetchRequests(userId: user.id, status: status);
});

/// 요청 상세 정보 Provider
final requestDetailProvider = FutureProvider.autoDispose
    .family<PaymentRequest?, String>((ref, requestId) async {
  final service = ref.watch(requestServiceProvider);
  return service.fetchRequest(requestId);
});

