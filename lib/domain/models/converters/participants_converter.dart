import 'dart:convert';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../participants.dart';

class ParticipantsConverter
    extends JsonConverter<List<ParticipantShare>, dynamic> {
  const ParticipantsConverter({this.tolerance = 1e-3});

  final double tolerance;

  @override
  List<ParticipantShare> fromJson(dynamic json) {
    if (json == null) {
      return const [];
    }
    final rawList = switch (json) {
      final String value when value.isEmpty => <dynamic>[],
      final String value => jsonDecode(value) as List<dynamic>,
      final List<dynamic> value => value,
      _ => throw const FormatException('participants 필드는 배열이어야 합니다.'),
    };

    final shares = rawList
        .map((dynamic item) {
          if (item is ParticipantShare) {
            return item;
          }
          if (item is Map<String, dynamic>) {
            return ParticipantShare.fromJson(item);
          }
          if (item is Map) {
            return ParticipantShare.fromJson(
              Map<String, dynamic>.from(item as Map),
            );
          }
          throw const FormatException('지원하지 않는 participants 항목 타입입니다.');
        })
        .toList(growable: false);

    final errors = validateParticipantShares(shares, tolerance: tolerance);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(', '));
    }

    return shares;
  }

  @override
  dynamic toJson(List<ParticipantShare> shares) =>
      shares.map((share) => share.toJson()).toList(growable: false);
}

List<String> validateParticipantShares(
  List<ParticipantShare> shares, {
  double tolerance = 1e-3,
}) {
  if (shares.isEmpty) {
    return const ['participants 리스트가 비어 있습니다.'];
  }

  final errors = <String>[];
  final seen = <String>{};
  double ratioSum = 0;

  for (final share in shares) {
    ratioSum += share.ratio;
    if (share.ratio <= 0) {
      errors.add('${share.userId} 비율은 0보다 커야 합니다.');
    }
    if (!seen.add(share.userId)) {
      errors.add('사용자 ${share.userId} 가 중복되었습니다.');
    }
  }

  final rounded = (ratioSum * 1000).roundToDouble() / 1000;
  if (abs(1 - rounded) > tolerance) {
    errors.add('participants 비율 합이 1과 ${tolerance.toStringAsPrecision(1)} 이내가 아닙니다. (합계: $ratioSum)');
  }

  return errors;
}
