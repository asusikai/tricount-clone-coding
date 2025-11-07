import 'package:flutter/material.dart';

/// 재시도 액션 전용 버튼.
///
/// 로딩 상태와 기본 아이콘/레이블을 제공해 에러 화면 등에서
/// 일관된 UX를 유지할 수 있도록 돕는다.
class RetryButton extends StatelessWidget {
  const RetryButton({
    super.key,
    required this.onPressed,
    this.label = '다시 시도',
    this.icon = Icons.refresh,
    this.isLoading = false,
  });

  /// 버튼을 눌렀을 때 호출되는 콜백.
  final VoidCallback onPressed;

  /// 버튼에 표시할 텍스트. 기본값은 '다시 시도'.
  final String label;

  /// 버튼에 표시할 아이콘. 기본값은 새로고침 아이콘.
  final IconData icon;

  /// true이면 진행 인디케이터를 보여주고 버튼을 비활성화한다.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}
