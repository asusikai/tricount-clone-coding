import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../domain/models/models.dart';
import '../../presentation/providers/group_providers.dart';

Future<bool?> showGroupEditDialog(
  BuildContext context, {
  required GroupDto group,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => GroupEditDialog(group: group),
  );
}

class GroupEditDialog extends ConsumerStatefulWidget {
  const GroupEditDialog({super.key, required this.group});

  final GroupDto group;

  @override
  ConsumerState<GroupEditDialog> createState() => _GroupEditDialogState();
}

class _GroupEditDialogState extends ConsumerState<GroupEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _selectedCurrency;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    final supported = CurrencyConstants.supportedCurrencies;
    final currentCurrency = widget.group.baseCurrency;
    _selectedCurrency = supported.contains(currentCurrency)
        ? currentCurrency
        : CurrencyConstants.defaultCurrency;
  }

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
    final result = await controller.updateGroup(
      groupId: widget.group.id,
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
        SnackBarHelper.showError(
          context,
          '그룹 수정 실패: ${error.message}',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('그룹 정보 수정'),
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
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return '그룹 이름을 입력해주세요.';
                }
                if (trimmed.length > AppConstants.maxGroupNameLength) {
                  return '그룹 이름은 ${AppConstants.maxGroupNameLength}자 이하여야 합니다.';
                }
                return null;
              },
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              items: CurrencyConstants.supportedCurrencies
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    ),
                  )
                  .toList(growable: false),
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
              : const Text('저장'),
        ),
      ],
    );
  }
}

