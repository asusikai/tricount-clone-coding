import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:gotrue/gotrue.dart' as gotrue;

import 'app_exception.dart';

/// 통일된 에러 처리 유틸리티
/// 
/// 다양한 예외 타입을 AppException 계층으로 변환하고,
/// 사용자 친화적인 메시지를 제공합니다.
class ErrorHandler {
  ErrorHandler._();

  /// 예외를 AppException으로 변환
  /// 
  /// [error] 변환할 예외
  /// [stackTrace] 스택 트레이스 (있는 경우)
  /// [defaultMessage] 기본 메시지 (에러 타입을 알 수 없을 때 사용)
  static AppException toAppException(
    Object error, {
    StackTrace? stackTrace,
    String? defaultMessage,
  }) {
    // 이미 AppException인 경우 그대로 반환
    if (error is AppException) {
      return error;
    }

    // SupabaseException 처리
    if (error is gotrue.AuthException) {
      return AuthException(
        _getAuthErrorMessage(error),
        cause: error,
        stackTrace: stackTrace,
      );
    }

    if (error is PostgrestException) {
      return _handlePostgrestException(error, stackTrace);
    }

    if (error is StorageException) {
      return NetworkException(
        '파일 저장소 오류가 발생했습니다.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 일반 Exception 처리
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('로그인이 필요')) {
        return AuthException(
          '로그인이 필요합니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      if (message.contains('권한') || message.contains('permission')) {
        return PermissionException(
          '권한이 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      if (message.contains('찾을 수 없') || message.contains('not found')) {
        return NotFoundException(
          '요청한 리소스를 찾을 수 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
      if (message.contains('중복') || message.contains('duplicate')) {
        return ConflictException(
          '이미 존재하는 항목입니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      }
    }

    // 네트워크 관련 오류 감지
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return NetworkException(
        '네트워크 연결 오류가 발생했습니다. 인터넷 연결을 확인해주세요.',
        cause: error,
        stackTrace: stackTrace,
      );
    }

    // 알 수 없는 예외
    return UnknownException(
      defaultMessage ?? '알 수 없는 오류가 발생했습니다.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  /// PostgrestException을 적절한 AppException으로 변환
  static AppException _handlePostgrestException(
    PostgrestException error,
    StackTrace? stackTrace,
  ) {
    final code = error.code;
    final message = error.message;

    // HTTP 상태 코드 기반 분류
    switch (code) {
      case 'PGRST116': // Not found
        return NotFoundException(
          '요청한 데이터를 찾을 수 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      case '23505': // Unique violation
        return ConflictException(
          '이미 존재하는 항목입니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      case '23503': // Foreign key violation
        return ValidationException(
          '관련된 데이터가 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      case '42501': // Insufficient privilege
        return PermissionException(
          '권한이 없습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
      default:
        // 메시지 기반 분류
        if (message.contains('JWT') || message.contains('token')) {
          return AuthException(
            '인증이 만료되었습니다. 다시 로그인해주세요.',
            cause: error,
            stackTrace: stackTrace,
          );
        }
        if (message.contains('network') || message.contains('connection')) {
          return NetworkException(
            '네트워크 연결 오류가 발생했습니다.',
            cause: error,
            stackTrace: stackTrace,
          );
        }
        return NetworkException(
          message.isNotEmpty ? message : '데이터베이스 오류가 발생했습니다.',
          cause: error,
          stackTrace: stackTrace,
        );
    }
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

  /// 예외를 사용자 친화적인 메시지로 변환
  /// 
  /// [error] 변환할 예외
  /// [defaultMessage] 기본 메시지
  static String toUserFriendlyMessage(
    Object error, {
    String? defaultMessage,
  }) {
    final appException = toAppException(
      error,
      defaultMessage: defaultMessage,
    );
    return appException.message;
  }

  /// 예외를 로깅하고 AppException으로 변환
  /// 
  /// [error] 변환할 예외
  /// [stackTrace] 스택 트레이스
  /// [context] 컨텍스트 메시지 (로깅용)
  /// [defaultMessage] 기본 메시지
  static AppException handleAndLog(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    String? defaultMessage,
  }) {
    final appException = toAppException(
      error,
      stackTrace: stackTrace,
      defaultMessage: defaultMessage,
    );

    // 디버그 모드에서만 상세 로깅
    if (kDebugMode) {
      debugPrint('${context ?? '에러 발생'}: ${appException.message}');
      if (appException.cause != null) {
        debugPrint('원본 예외: ${appException.cause}');
      }
      if (stackTrace != null) {
        debugPrint('스택 트레이스: $stackTrace');
      }
    }

    return appException;
  }
}

