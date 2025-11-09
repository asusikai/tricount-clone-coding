enum AppExceptionType {
  unknown,
  network,
  unauthorized,
  forbidden,
  validation,
  conflict,
  notFound,
}

/// 앱 전역에서 사용하는 커스텀 예외 클래스
///
/// 모든 예외는 이 클래스 계층을 통해 처리됩니다.
abstract class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  AppExceptionType get type;

  /// 사용자에게 표시할 메시지
  final String message;

  /// 원본 예외 (있는 경우)
  final Object? cause;

  /// 스택 트레이스 (있는 경우)
  final StackTrace? stackTrace;

  @override
  String toString() => message;
}

/// 네트워크 관련 예외
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionType get type => AppExceptionType.network;
}

/// 인증 관련 예외
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionType get type => AppExceptionType.unauthorized;
}

/// 권한 관련 예외
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionType get type => AppExceptionType.forbidden;
}

/// 리소스를 찾을 수 없을 때 발생하는 예외
class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionType get type => AppExceptionType.notFound;
}

/// 잘못된 입력이나 요청일 때 발생하는 예외
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionType get type => AppExceptionType.validation;
}

/// 충돌이 발생했을 때 (예: 중복 가입) 발생하는 예외
class ConflictException extends AppException {
  const ConflictException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionType get type => AppExceptionType.conflict;
}

/// 알 수 없는 예외
class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.cause,
    super.stackTrace,
  });

  @override
  AppExceptionType get type => AppExceptionType.unknown;
}





















