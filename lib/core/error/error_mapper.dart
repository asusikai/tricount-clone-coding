import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gotrue/gotrue.dart' as gotrue;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_error.dart';

/// 예외를 AppError로 매핑하는 유틸리티
///
/// Supabase/플랫폼 예외를 표준화된 AppError로 변환합니다.
class ErrorMapper {
  ErrorMapper._();

  /// 예외를 AppError로 변환
  ///
  /// [error] 변환할 예외
  /// [stackTrace] 스택 트레이스 (있는 경우)
  /// [defaultMessage] 기본 메시지
  static AppError toAppError(
    Object error, {
    StackTrace? stackTrace,
    String? defaultMessage,
  }) {
    // 이미 AppError인 경우 그대로 반환
    if (error is AppError) {
      return error;
    }

    // Supabase AuthException 처리
    if (error is gotrue.AuthException) {
      return _mapAuthException(error, stackTrace);
    }

    // PlatformException 처리
    if (error is PlatformException) {
      return _mapPlatformException(error, stackTrace);
    }

    // PostgrestException 처리
    if (error is PostgrestException) {
      return _mapPostgrestException(error, stackTrace);
    }

    // StorageException 처리
    if (error is StorageException) {
      return NetworkError(
        message: '파일 저장소 오류가 발생했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 일반 Exception 처리
    if (error is Exception) {
      return _mapGenericException(error, stackTrace, defaultMessage);
    }

    // 알 수 없는 예외
    return UnknownError(
      message: defaultMessage ?? '알 수 없는 오류가 발생했습니다.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// Supabase AuthException을 AppError로 매핑
  static AppError _mapAuthException(
    gotrue.AuthException error,
    StackTrace? stackTrace,
  ) {
    final message = error.message.toLowerCase();

    // 취소된 경우
    if (message.contains('cancelled') ||
        message.contains('canceled') ||
        message.contains('취소')) {
      return CancelledError(
        message: '로그인이 취소되었습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 토큰 만료
    if (message.contains('token') ||
        message.contains('expired') ||
        message.contains('만료')) {
      return AuthError(
        message: '인증이 만료되었습니다. 다시 로그인해주세요.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 네트워크 오류
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return NetworkError(
        message: '네트워크 연결 오류가 발생했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 일반 인증 오류
    return AuthError(
      message: _getAuthErrorMessage(error),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// PlatformException을 AppError로 매핑
  static AppError _mapPlatformException(
    PlatformException error,
    StackTrace? stackTrace,
  ) {
    final code = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';

    // 네트워크 관련
    if (code.contains('network') ||
        code.contains('connection') ||
        message.contains('network') ||
        message.contains('connection')) {
      return NetworkError(
        message: '네트워크 연결 오류가 발생했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 취소된 경우
    if (code.contains('cancelled') ||
        code.contains('canceled') ||
        message.contains('cancelled') ||
        message.contains('canceled')) {
      return CancelledError(
        message: '작업이 취소되었습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 권한 관련
    if (code.contains('permission') || message.contains('permission')) {
      return PermissionError(
        message: '권한이 없습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 알 수 없는 플랫폼 오류
    return UnknownError(
      message: error.message ?? '플랫폼 오류가 발생했습니다.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// PostgrestException을 AppError로 매핑
  static AppError _mapPostgrestException(
    PostgrestException error,
    StackTrace? stackTrace,
  ) {
    final code = error.code;
    final message = error.message;

    switch (code) {
      case 'PGRST116': // Not found
        return NotFoundError(
          message: '요청한 데이터를 찾을 수 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      case '23505': // Unique violation
        return ValidationError(
          message: '이미 존재하는 항목입니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      case '23503': // Foreign key violation
        return ValidationError(
          message: '관련된 데이터가 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      case '42501': // Insufficient privilege
        return PermissionError(
          message: '권한이 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      default:
        // 메시지 기반 분류
        if (message.contains('JWT') || message.contains('token')) {
          return AuthError(
            message: '인증이 만료되었습니다. 다시 로그인해주세요.',
            cause: error,
            stackTrace: stackTrace,
          );
        }
        if (message.contains('network') || message.contains('connection')) {
          return NetworkError(
            message: '네트워크 연결 오류가 발생했습니다.',
            cause: error,
            stackTrace: stackTrace,
          );
        }
        return NetworkError(
          message: message.isNotEmpty
              ? message
              : '데이터베이스 오류가 발생했습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
    }
  }

  /// 일반 Exception을 AppError로 매핑
  static AppError _mapGenericException(
    Exception error,
    StackTrace? stackTrace,
    String? defaultMessage,
  ) {
    final message = error.toString().toLowerCase();

    // 네트워크 관련
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('socket')) {
      return NetworkError(
        message: '네트워크 연결 오류가 발생했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 인증 관련
    if (message.contains('로그인이 필요') ||
        message.contains('auth') ||
        message.contains('인증')) {
      return AuthError(
        message: '로그인이 필요합니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 권한 관련
    if (message.contains('권한') || message.contains('permission')) {
      return PermissionError(
        message: '권한이 없습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 찾을 수 없음
    if (message.contains('찾을 수 없') || message.contains('not found')) {
      return NotFoundError(
        message: '요청한 리소스를 찾을 수 없습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 취소
    if (message.contains('취소') ||
        message.contains('cancelled') ||
        message.contains('canceled')) {
      return CancelledError(
        message: '작업이 취소되었습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 알 수 없는 예외
    return UnknownError(
      message: defaultMessage ?? '알 수 없는 오류가 발생했습니다.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// AuthException의 사용자 친화적인 메시지 반환
  static String _getAuthErrorMessage(gotrue.AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('email') && message.contains('already')) {
      return '이미 사용 중인 이메일입니다.';
    }
    if (message.contains('invalid') && message.contains('credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (message.contains('token') || message.contains('expired')) {
      return '인증이 만료되었습니다. 다시 로그인해주세요.';
    }
    if (message.contains('cancelled') || message.contains('canceled')) {
      return '로그인이 취소되었습니다.';
    }
    return error.message;
  }

  /// AppError를 로깅하고 반환
  ///
  /// [error] 변환할 예외
  /// [stackTrace] 스택 트레이스
  /// [context] 컨텍스트 메시지 (로깅용)
  /// [defaultMessage] 기본 메시지
  static AppError mapAndLog(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    String? defaultMessage,
  }) {
    final appError = toAppError(
      error,
      stackTrace: stackTrace,
      defaultMessage: defaultMessage,
    );

    // 디버그 모드에서만 상세 로깅
    if (kDebugMode) {
      debugPrint('${context ?? '에러 발생'}: ${appError.message}');
      if (appError.cause != null) {
        debugPrint('원본 예외: ${appError.cause}');
      }
      if (stackTrace != null) {
        debugPrint('스택 트레이스: $stackTrace');
      }
    }

    return appError;
  }
}

