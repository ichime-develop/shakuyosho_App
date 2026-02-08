import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';

class CommonBottomNavBar extends StatelessWidget {
  const CommonBottomNavBar({super.key, required this.currentIndex});
  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    AppLog.ui('bottom_nav_tap', ctx: context, data: {'index': index});
    switch (index) {
      case 0:
        context.go('/to0100/personal');
        break;
      case 1:
        context.go('/fr0100');
        break;
      case 2:
        context.go('/ev0100');
        break;
      case 3:
        context.go('/my0100');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItemData(
        iconFilled: Icons.home,
        iconOutlined: Icons.home_outlined,
        label: 'ほーむ',
      ),
      _NavItemData(
        iconFilled: Icons.group,
        iconOutlined: Icons.group_outlined,
        label: 'ともだち',
      ),
      _NavItemData(
        iconFilled: Icons.event_note,
        iconOutlined: Icons.event_note_outlined,
        label: 'イベント',
      ),
      _NavItemData(
        iconFilled: Icons.person,
        iconOutlined: Icons.person_outline,
        label: 'じぶん',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(20, 0, 0, 0),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final selected = currentIndex == index;
          final data = items[index];
          final color = selected
              ? AppColors.navSelectedIcon
              : AppColors.navUnselectedIcon;
          final iconData = selected ? data.iconFilled : data.iconOutlined;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onTap(context, index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconData, color: color, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      data.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.iconFilled,
    required this.iconOutlined,
    required this.label,
  });
  final IconData iconFilled;
  final IconData iconOutlined;
  final String label;
}
