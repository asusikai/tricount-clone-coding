import 'package:flutter/material.dart';

/// 공통 에러 표시 위젯
/// 
/// 에러 발생 시 사용자에게 표시할 에러 메시지와 재시도 버튼을 제공합니다.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.message,
  });

  /// 에러 객체
  final Object error;

  /// 재시도 콜백 (null이면 재시도 버튼이 표시되지 않음)
  final VoidCallback? onRetry;

  /// 커스텀 제목 (null이면 기본 메시지 사용)
  final String? title;

  /// 커스텀 메시지 (null이면 error.toString() 사용)
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              title ?? '오류가 발생했습니다',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

