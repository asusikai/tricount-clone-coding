import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../common/services/auth_service.dart';
import '../../common/services/bank_account_service.dart';
import '../../common/services/profile_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _accounts = <Map<String, dynamic>>[];
  bool _isProfileLoading = true;
  bool _isAccountLoading = true;

  bool get _isLoading => _isProfileLoading && _isAccountLoading;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshAll());
  }

  Future<void> _refreshAll() async {
    await Future.wait<void>(<Future<void>>[_loadProfile(), _loadAccounts()]);
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = null;
        _isProfileLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isProfileLoading = true;
      });
    }

    try {
      final profile = await ref
          .read(profileServiceProvider)
          .fetchProfile(user.id);
      if (!mounted) {
        return;
      }

      final fallback =
          <String, dynamic>{
            'email': user.email,
            'name': user.userMetadata?['full_name'],
            'nickname': user.userMetadata?['nickname'],
            'provider': user.appMetadata['provider'],
          }..removeWhere(
            (key, value) => value == null || (value is String && value.isEmpty),
          );

      setState(() {
        _profile = {...fallback, if (profile != null) ...profile};
        _isProfileLoading = false;
      });
    } catch (error) {
      debugPrint('프로필 로드 실패: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('프로필을 불러오지 못했습니다: $error')));
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  Future<void> _loadAccounts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = <Map<String, dynamic>>[];
        _isAccountLoading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _isAccountLoading = true;
      });
    }

    try {
      final accounts = await ref
          .read(bankAccountServiceProvider)
          .fetchAccounts(user.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = accounts;
        _isAccountLoading = false;
      });
    } catch (error) {
      debugPrint('계좌 로드 실패: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계좌 정보를 불러오지 못했습니다: $error')));
      setState(() {
        _isAccountLoading = false;
      });
    }
  }

  Future<void> _editName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final currentName = (_profile?['name'] as String?) ?? '';
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('이름 수정'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: '실명'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty || result == currentName) {
      return;
    }

    try {
      await ref.read(profileServiceProvider).updateName(user.id, result);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = {...?_profile, 'name': result};
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이름이 업데이트되었습니다.')));
    } catch (error) {
      debugPrint('이름 업데이트 실패: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이름 수정 실패: $error')));
    }
  }

  Future<void> _editNickname() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final currentNickname = (_profile?['nickname'] as String?) ?? '';
    final controller = TextEditingController(text: currentNickname);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('닉네임 수정'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: '닉네임'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty || result == currentNickname) {
      return;
    }

    try {
      await ref.read(profileServiceProvider).updateNickname(user.id, result);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = {...?_profile, 'nickname': result};
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('닉네임이 업데이트되었습니다.')));
    } catch (error) {
      debugPrint('닉네임 업데이트 실패: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('닉네임 수정 실패: $error')));
    }
  }

  Future<void> _addAccount() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final bankController = TextEditingController();
    final numberController = TextEditingController();
    final aliasController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계좌 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankController,
                decoration: const InputDecoration(labelText: '은행명'),
              ),
              TextField(
                controller: numberController,
                decoration: const InputDecoration(labelText: '계좌번호'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: aliasController,
                decoration: const InputDecoration(labelText: '메모 (선택)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('추가'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final bankName = bankController.text.trim();
    final accountNumber = numberController.text.trim();
    final alias = aliasController.text.trim();

    // 프로필에서 사용자 이름 가져오기 (이미 로드된 데이터 사용)
    final userName = (_profile?['name'] as String?)?.trim();
    final accountHolder = userName?.isNotEmpty == true ? userName : null;

    if (bankName.isEmpty || accountNumber.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('은행명과 계좌번호를 입력해주세요.')));
      return;
    }

    try {
      final account = await ref
          .read(bankAccountServiceProvider)
          .addAccount(
            userId: user.id,
            bankName: bankName,
            accountNumber: accountNumber,
            accountHolder: accountHolder,
            memo: alias.isEmpty ? null : alias,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = <Map<String, dynamic>>[account, ..._accounts];
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('계좌가 추가되었습니다.')));
    } catch (error) {
      debugPrint('계좌 추가 실패: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계좌 추가 실패: $error')));
    }
  }

  Future<void> _deleteAccount(String accountId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계좌 삭제'),
          content: const Text('선택한 계좌를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(bankAccountServiceProvider).deleteAccount(accountId);
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = _accounts
            .where((account) => account['id'] != accountId)
            .toList(growable: false);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('계좌가 삭제되었습니다.')));
    } catch (error) {
      debugPrint('계좌 삭제 실패: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('계좌 삭제 실패: $error')));
    }
  }

  Future<void> _copyAccountNumber(String accountNumber) async {
    await Clipboard.setData(ClipboardData(text: accountNumber));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('계좌번호가 복사되었습니다.')));
  }

  String _maskedAccountNumber(String value) {
    if (value.length <= 4) {
      return value;
    }
    final visible = value.substring(value.length - 4);
    return '${'*' * (value.length - 4)}$visible';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    final email = _profile?['email'] as String? ?? user.email ?? '';
    final name = (_profile?['name'] as String?)?.trim();
    final nickname = (_profile?['nickname'] as String?)?.trim();

    final displayName = (name?.isNotEmpty ?? false) ? name! : '이름 미설정';
    final avatarLabel = ((displayName.isNotEmpty ? displayName[0] : email[0]))
        .toUpperCase();

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(avatarLabel, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(email, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tag_faces_outlined),
                  title: const Text('닉네임'),
                  subtitle: Text(
                    nickname?.isNotEmpty == true ? nickname! : '등록된 닉네임이 없습니다',
                  ),
                  trailing: TextButton(
                    onPressed: _editNickname,
                    child: const Text('수정'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance_outlined),
                    title: const Text('은행 계좌'),
                    trailing: TextButton.icon(
                      onPressed: _addAccount,
                      icon: const Icon(Icons.add),
                      label: const Text('추가'),
                    ),
                  ),
                  if (_isAccountLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_accounts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      child: Text(
                        '등록된 계좌가 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _accounts.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final account = _accounts[index];
                        final bankName =
                            (account['bank_name'] as String?) ?? '은행';
                        final number =
                            (account['account_number'] as String?) ?? '';
                        final alias = account['alias'] as String?;
                        return ListTile(
                          title: Text(bankName),
                          subtitle: Text(
                            [
                              _maskedAccountNumber(number),
                              if (alias != null && alias.isNotEmpty) alias,
                            ].join(' • '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'copy':
                                  unawaited(_copyAccountNumber(number));
                                  break;
                                case 'delete':
                                  unawaited(
                                    _deleteAccount(account['id'] as String),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: 'copy',
                                child: Text('계좌번호 복사'),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('삭제'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (!mounted) {
                  return;
                }
                context.go('/splash');
              },
            ),
          ),
        ],
      ),
    );
  }
}
