import 'package:freezed_annotation/freezed_annotation.dart';

part 'participants.freezed.dart';
part 'participants.g.dart';

@freezed
class ParticipantShare with _$ParticipantShare {
  const factory ParticipantShare({
    @JsonKey(name: 'user_id') required String userId,
    required double ratio,
    double? amount,
  }) = _ParticipantShare;

  factory ParticipantShare.fromJson(Map<String, dynamic> json) =>
      _$ParticipantShareFromJson(json);
}
