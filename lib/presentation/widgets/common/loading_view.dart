import 'package:flutter/material.dart';

/// 공통 로딩 표시 위젯
/// 
/// 데이터를 불러오는 중일 때 표시할 로딩 인디케이터입니다.
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message,
    this.padding,
  });

  /// 로딩 메시지 (선택사항)
  final String? message;

  /// 패딩 (기본값: EdgeInsets.all(24))
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      const CircularProgressIndicator(),
    ];

    if (message != null) {
      children.addAll([
        const SizedBox(height: 16),
        Text(
          message!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
        ),
      ]);
    }

    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

