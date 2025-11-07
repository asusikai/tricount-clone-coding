import 'package:flutter/material.dart';

/// 정보 행 표시 위젯
/// 
/// 아이콘, 레이블, 값을 가진 정보 행을 표시합니다.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.labelStyle,
    this.valueStyle,
  });

  /// 아이콘
  final IconData icon;

  /// 레이블 텍스트
  final String label;

  /// 값 텍스트
  final String value;

  /// 아이콘 색상 (기본값: Theme의 primary color)
  final Color? iconColor;

  /// 레이블 스타일
  final TextStyle? labelStyle;

  /// 값 스타일
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? theme.colorScheme.primary;
    final defaultLabelStyle = labelStyle ??
        const TextStyle(
          fontWeight: FontWeight.w600,
        );

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: defaultIconColor,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: defaultLabelStyle,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

