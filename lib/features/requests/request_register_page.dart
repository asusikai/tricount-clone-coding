import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/utils.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/widgets/common/common_widgets.dart';

class RequestRegisterPage extends ConsumerStatefulWidget {
  const RequestRegisterPage({super.key});

  @override
  ConsumerState<RequestRegisterPage> createState() =>
      _RequestRegisterPageState();
}

class _RequestRegisterPageState extends ConsumerState<RequestRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  List<Map<String, dynamic>> _groups = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _members = <Map<String, dynamic>>[];
  String? _selectedGroupId;
  String? _selectedUserId;
  bool _isLoading = true;
  bool _isLoadingMembers = false;
  bool _isSubmitting = false;

  Map<String, dynamic>? get _selectedGroup => _groups.firstWhere(
        (group) => group['id'] == _selectedGroupId,
        orElse: () => <String, dynamic>{},
      );

  @override
  void initState() {
    super.initState();
    unawaited(_loadGroups());
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final groups = await ref.read(groupServiceProvider).getUserGroups();
      if (!mounted) {
        return;
      }
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('그룹 목록 로드 실패: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      SnackBarHelper.showError(
        context,
        '그룹 목록을 불러오지 못했습니다: $error',
      );
    }
  }

  Future<void> _loadMembers(String groupId) async {
    setState(() {
      _isLoadingMembers = true;
    });

    try {
      final members =
          await ref.read(groupServiceProvider).getGroupMembers(groupId);
      if (!mounted) {
        return;
      }

      final currentUser = Supabase.instance.client.auth.currentUser;

      setState(() {
        _members = members
            .where(
              (member) => member['id'] != currentUser?.id,
            )
            .toList(growable: false);
        _selectedUserId = null;
        _isLoadingMembers = false;
      });
    } catch (error) {
      debugPrint('멤버 목록 로드 실패: $error');
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMembers = false;
      });
      SnackBarHelper.showError(
        context,
        '그룹 멤버를 불러오지 못했습니다: $error',
      );
    }
  }

  Future<void> _submit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      SnackBarHelper.showError(context, '로그인이 필요합니다.');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      SnackBarHelper.showError(context, '금액을 올바르게 입력해주세요.');
      return;
    }

    final groupId = _selectedGroupId;
    final toUserId = _selectedUserId;
    if (groupId == null || toUserId == null) {
      SnackBarHelper.showError(
        context,
        '그룹과 송금 받을 사용자를 선택해주세요.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final group = _selectedGroup;
      final currency = (group?['base_currency'] as String?) ?? 'KRW';

      await ref.read(requestServiceProvider).createRequest(
            groupId: groupId,
            fromUserId: user.id,
            toUserId: toUserId,
            amount: amount,
            currency: currency,
            memo: _memoController.text.trim().isEmpty
                ? null
                : _memoController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      SnackBarHelper.showSuccess(context, '송금 요청이 등록되었습니다.');
      Navigator.of(context).pop(true);
    } catch (error) {
      debugPrint('요청 등록 실패: $error');
      if (!mounted) {
        return;
      }
      SnackBarHelper.showError(context, '송금 요청 등록 실패: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('송금 요청 등록'),
      ),
      body: _isLoading
          ? const LoadingView(message: '그룹 정보를 불러오는 중입니다...')
          : _groups.isEmpty
              ? EmptyStateView(
                  icon: Icons.group_add_outlined,
                  title: '가입된 그룹이 없습니다.',
                  message: '먼저 그룹에 참여하거나 새로운 그룹을 만들어주세요.',
                  action: RetryButton(
                    label: '그룹 목록 새로고침',
                    onPressed: () => unawaited(_loadGroups()),
                  ),
                )
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedGroupId,
                            decoration:
                                const InputDecoration(labelText: '그룹 선택'),
                            items: _groups
                                .map(
                                  (group) => DropdownMenuItem<String>(
                                    value: group['id'] as String,
                                    child: Text(
                                      group['name'] as String? ?? '이름 없음',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGroupId = value;
                              });
                              if (value != null) {
                                unawaited(_loadMembers(value));
                              }
                            },
                            validator: (value) =>
                                value == null ? '그룹을 선택해주세요.' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedUserId,
                            decoration:
                                const InputDecoration(labelText: '송금 대상'),
                            items: _members
                                .map(
                                  (member) => DropdownMenuItem<String>(
                                    value: member['id'] as String,
                                    child: Text(
                                      (member['nickname'] as String?) ??
                                          (member['name'] as String?) ??
                                          (member['email'] as String?) ??
                                          '이름 없음',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUserId = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? '송금 대상을 선택해주세요.' : null,
                            disabledHint: const Text('그룹을 먼저 선택해주세요.'),
                            isExpanded: true,
                          ),
                          if (_isLoadingMembers)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: '금액',
                              suffixText:
                                  (_selectedGroup?['base_currency'] as String?) ??
                                      'KRW',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^[0-9]*\.?[0-9]{0,2}$'),
                              ),
                            ],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '금액을 입력해주세요.';
                              }
                              final parsed = double.tryParse(value);
                              if (parsed == null || parsed <= 0) {
                                return '올바른 금액을 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _memoController,
                            decoration: const InputDecoration(
                              labelText: '메모 (선택)',
                            ),
                            maxLength: 80,
                          ),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isSubmitting ? null : _submit,
                              icon: const Icon(Icons.send),
                              label: Text(
                                _isSubmitting ? '등록 중...' : '송금 요청 등록',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
