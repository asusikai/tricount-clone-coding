import 'package:flutter/material.dart';

import '../presentation/widgets/common/retry_button.dart';

typedef RetryCallback = Future<void> Function();

class BootstrapErrorPage extends StatelessWidget {
  const BootstrapErrorPage({
    super.key,
    required this.message,
    required this.onRetry,
    this.technicalDetails,
  });

  final String message;
  final RetryCallback onRetry;
  final String? technicalDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 60,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '앱을 시작할 수 없어요',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (technicalDetails != null &&
                      technicalDetails!.trim().isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _TechnicalDetailsBox(details: technicalDetails!),
                  ],
                  const SizedBox(height: 24),
                  RetryButton(onPressed: onRetry),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TechnicalDetailsBox extends StatelessWidget {
  const _TechnicalDetailsBox({required this.details});

  final String details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: SelectableText(
            details,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      ),
    );
  }
}
