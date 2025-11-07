import 'package:flutter/material.dart';

typedef FooterTapCallback = void Function(int index);

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final FooterTapCallback onTap;

  const AppFooter({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'ホーム'),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_2_outlined),
          label: 'ともだち',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'じぶん'),
      ],
    );
  }
}
