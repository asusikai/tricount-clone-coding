import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/services/group_service.dart';
import '../../core/utils/utils.dart';

class GroupCreatePage extends ConsumerStatefulWidget {
  const GroupCreatePage({super.key});

  @override
  ConsumerState<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends ConsumerState<GroupCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCurrency = 'KRW';

  final List<String> _currencies = ['KRW', 'USD', 'EUR', 'JPY', 'CNY', 'GBP'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(groupServiceProvider)
          .createGroup(
            name: _nameController.text.trim(),
            baseCurrency: _selectedCurrency,
          );

      if (!mounted) return;

      SnackBarHelper.showSuccess(context, '그룹이 생성되었습니다.');

      ref.invalidate(userGroupsProvider);

      // 홈으로 돌아가기
      context.go('/home');
    } catch (e) {
      if (!mounted) return;

      SnackBarHelper.showError(context, '그룹 생성 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('새 그룹 만들기')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '그룹 이름',
                hintText: '예: 제주도 여행',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '그룹 이름을 입력해주세요.';
                }
                if (value.trim().length > 50) {
                  return '그룹 이름은 50자 이하여야 합니다.';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              decoration: const InputDecoration(
                labelText: '기본 통화',
                border: OutlineInputBorder(),
              ),
              items: _currencies.map((currency) {
                return DropdownMenuItem(value: currency, child: Text(currency));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createGroup,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('그룹 만들기'),
            ),
          ],
        ),
      ),
    );
  }
}
