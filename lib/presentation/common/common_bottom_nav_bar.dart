import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';

class CommonBottomNavBar extends StatelessWidget {
  const CommonBottomNavBar({super.key, required this.currentIndex});
  final int currentIndex;

  void _onTap(BuildContext context, int i) {
    final dest = i == 0 ? 'friends' : (i == 1 ? 'home' : 'me');
    AppLog.ui('bottom_nav_tap', ctx: context, data: {'index': i, 'dest': dest});
    switch (i) {
      case 0:
        context.go('/fr0100');
        break;
      case 1:
        context.go('/to0100/personal');
        break;
      case 2:
        context.go('/my0100');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) => _onTap(context, i),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.people_outline), label: 'ともだち'),
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'ホーム'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'じぶん'),
      ],
    );
  }
}
