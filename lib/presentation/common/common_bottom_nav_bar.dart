import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/core/utils/app_logger.dart';

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
    final theme = Theme.of(context);
    final items = [
      _NavItemData(icon: Icons.home, label: 'ほーむ'),
      _NavItemData(icon: Icons.group, label: 'ともだち'),
      _NavItemData(icon: Icons.event_note, label: 'いべんと'),
      _NavItemData(icon: Icons.person, label: 'じぶん'),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
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
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5);
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _onTap(context, index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(data.icon, color: color, size: 24),
                        const SizedBox(height: 4),
                        Text(
                          data.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
