import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../presentation/providers/group_providers.dart';

Future<bool?> showGroupCreateDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const GroupCreateDialog(),
  );
}

class GroupCreateDialog extends ConsumerStatefulWidget {
  const GroupCreateDialog({super.key});

  @override
  ConsumerState<GroupCreateDialog> createState() => _GroupCreateDialogState();
}

class _GroupCreateDialogState extends ConsumerState<GroupCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCurrency = CurrencyConstants.defaultCurrency;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final controller = ref.read(groupListControllerProvider.notifier);
    final result = await controller.createGroup(
      name: _nameController.text.trim(),
      baseCurrency: _selectedCurrency,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    result.fold(
      onSuccess: (_) {
        Navigator.of(context).pop(true);
      },
      onFailure: (error) {
        SnackBarHelper.showError(context, '그룹 생성 실패: ${error.message}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 그룹 만들기'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '그룹 이름',
                hintText: '예: 제주도 여행',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '그룹 이름을 입력해주세요.';
                }
                if (value.trim().length > AppConstants.maxGroupNameLength) {
                  return '그룹 이름은 ${AppConstants.maxGroupNameLength}자 이하여야 합니다.';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCurrency,
              items: CurrencyConstants.supportedCurrencies
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    ),
                  )
                  .toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCurrency = value;
                        });
                      }
                    },
              decoration: const InputDecoration(labelText: '기본 통화'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('생성'),
        ),
      ],
    );
  }
}
