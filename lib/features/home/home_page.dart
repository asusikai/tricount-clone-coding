import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../domain/models/models.dart';
import '../../presentation/providers/providers.dart';
import '../group/group_create_dialog.dart';
import 'groups_tab.dart';
import '../profile/profile_page.dart';
import '../requests/request_list_tab.dart';

enum HomeTab { groups, requests, profile }

extension HomeTabX on HomeTab {
  static HomeTab? maybeFromName(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final tab in HomeTab.values) {
      if (tab.name == normalized) {
        return tab;
      }
    }
    return null;
  }

  static HomeTab fromName(String? value, {HomeTab fallback = HomeTab.groups}) {
    return maybeFromName(value) ?? fallback;
  }

  String get routePath {
    return this == HomeTab.groups ? '/home' : '/home?tab=$name';
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
    this.initialTab = HomeTab.groups,
  });

  final HomeTab initialTab;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late HomeTab _currentTab;

  static const Map<HomeTab, String> _tabTitles = {
    HomeTab.groups: 'Groups',
    HomeTab.requests: 'Requests',
    HomeTab.profile: 'Profile',
  };
  static const Map<HomeTab, PageStorageKey<String>> _tabStorageKeys = {
    HomeTab.groups: PageStorageKey<String>('home_groups_tab'),
    HomeTab.requests: PageStorageKey<String>('home_requests_tab'),
    HomeTab.profile: PageStorageKey<String>('home_profile_tab'),
  };

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List.generate(HomeTab.values.length, (_) => GlobalKey<NavigatorState>());

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _switchToTab(widget.initialTab, resetStack: true);
    }
  }

  void _onTabSelected(int index) {
    final targetTab = HomeTab.values[index];
    final isReselect = _currentTab == targetTab;
    _switchToTab(targetTab, resetStack: isReselect);
  }

  void _switchToTab(HomeTab tab, {bool resetStack = false}) {
    if (resetStack) {
      final navigator = _navigatorKeys[tab.index].currentState;
      navigator?.popUntil((route) => route.isFirst);
    }
    if (_currentTab == tab) {
      return;
    }
    setState(() {
      _currentTab = tab;
    });
  }

  FloatingActionButton? _buildFab(BuildContext context) {
    switch (_currentTab) {
      case HomeTab.groups:
        return FloatingActionButton(
          onPressed: () async {
            final created = await showGroupCreateDialog(context);
            if (!mounted) {
              return;
            }
            if (created == true) {
              SnackBarHelper.showSuccess(context, '그룹이 생성되었습니다.');
            }
          },
          child: const Icon(Icons.add),
        );
      case HomeTab.requests:
        return FloatingActionButton(
          onPressed: () async {
            final shouldRefresh =
                await context.push<bool>(RouteConstants.requestRegister);
            if (!mounted) {
              return;
            }
            if (shouldRefresh == true) {
              ref.invalidate(requestListProvider(null));
              for (final status in SettlementStatus.values) {
                ref.invalidate(requestListProvider(status));
              }
            }
          },
          child: const Icon(Icons.note_add),
        );
      case HomeTab.profile:
        return null;
    }
  }

  Future<bool> _onWillPop() async {
    final navigator = _navigatorKeys[_currentTab.index].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }

    if (_currentTab != HomeTab.groups) {
      _switchToTab(HomeTab.groups);
      return false;
    }

    return true;
  }

  Widget _buildTabNavigator(HomeTab tab) {
    final key = _tabStorageKeys[tab];
    final Widget child;
    switch (tab) {
      case HomeTab.groups:
        child = const GroupsTab();
        break;
      case HomeTab.requests:
        child = const RequestsTab();
        break;
      case HomeTab.profile:
        child = const ProfilePage();
        break;
    }

    return TickerMode(
      enabled: _currentTab == tab,
      child: Navigator(
        key: _navigatorKeys[tab.index],
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => KeyedSubtree(
              key: key,
              child: child,
            ),
            settings: settings,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).maybePop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tabTitles[_currentTab]!),
        ),
        body: IndexedStack(
          index: _currentTab.index,
          children: HomeTab.values.map(_buildTabNavigator).toList(),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentTab.index,
          onDestinationSelected: _onTabSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: 'Groups',
            ),
            NavigationDestination(
              icon: Icon(Icons.request_page_outlined),
              selectedIcon: Icon(Icons.request_page),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: _buildFab(context),
      ),
    );
  }
}
