import 'package:flutter/material.dart';

/// 공통 빈 상태 표시 위젯
/// 
/// 데이터가 없을 때 표시할 빈 상태 화면입니다.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.padding,
  });

  /// 표시할 아이콘
  final IconData icon;

  /// 제목
  final String title;

  /// 부가 메시지 (선택사항)
  final String? message;

  /// 액션 버튼 (선택사항)
  final Widget? action;

  /// 패딩 (기본값: EdgeInsets.symmetric(horizontal: 24, vertical: 120))
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Icon(
        icon,
        size: 64,
        color: Colors.grey,
      ),
      const SizedBox(height: 16),
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    ];

    if (message != null) {
      children.addAll([
        const SizedBox(height: 8),
        Text(
          message!,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ]);
    }

    if (action != null) {
      children.addAll([
        const SizedBox(height: 24),
        action!,
      ]);
    }

    return Center(
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 120,
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

