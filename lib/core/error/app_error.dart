/// 앱 전역에서 사용하는 표준화된 에러 타입
///
/// 모든 에러는 이 sealed class를 통해 타입 안전하게 처리됩니다.
sealed class AppError {
  const AppError({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  /// 사용자에게 표시할 메시지
  final String message;

  /// 원본 예외 (있는 경우)
  final Object? cause;

  /// 스택 트레이스 (있는 경우)
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// 네트워크 관련 에러
final class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// 인증 관련 에러
final class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// 사용자 취소 에러
final class CancelledError extends AppError {
  const CancelledError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// 설정/환경 변수 관련 에러
final class ConfigError extends AppError {
  const ConfigError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// 권한 관련 에러
final class PermissionError extends AppError {
  const PermissionError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// 리소스를 찾을 수 없을 때 발생하는 에러
final class NotFoundError extends AppError {
  const NotFoundError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// 검증 실패 에러
final class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

/// 알 수 없는 에러
final class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}

