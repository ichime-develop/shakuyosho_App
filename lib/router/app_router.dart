import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/presentation/loan_book/lb0100Screen.dart';
import 'package:shakuyousho_app/presentation/transaction/tr0100Screen.dart';
import 'package:shakuyousho_app/presentation/top/to0100Screen.dart';

import '../presentation/splash/st0100screen.dart';
import '../presentation/group_make/gr0100screen.dart';
import '../presentation/group_make/gr0200Screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/st0100',
    // `/to0100` 直打ちを `/to0100/personal` へ逃がす（後方互換）
    redirect: (context, state) {
      if (state.fullPath == '/to0100') {
        return '/to0100/personal';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/st0100',
        name: 'ST0100',
        builder: (_, __) => const St0100SplashScreen(),
      ),

      // TO0100: タブ別のURL（個人/イベント）。現状は同一画面を返す。
      GoRoute(
        path: '/to0100/personal',
        name: 'TO0100_PERSONAL',
        builder: (_, __) => const To0100Screen(initialTab: 0),
      ),
      GoRoute(
        path: '/to0100/event',
        name: 'TO0100_EVENT',
        builder: (_, __) => const To0100Screen(initialTab: 1),
      ),

      // 既存ルート（互換用）。redirect で /to0100/personal に寄せる。
      GoRoute(
        path: '/to0100',
        name: 'TO0100',
        builder: (_, __) => const To0100Screen(),
      ),

      GoRoute(
        path: '/gr0100',
        name: 'GR0100',
        builder: (_, __) => const Gr0100GroupCreateScreen(),
      ),
      GoRoute(
        path: '/gr0200',
        name: 'GR0200',
        builder: (_, __) => const Gr0200GroupJoinScreen(),
      ),
      GoRoute(
        path: '/tr0100',
        name: 'TR0100',
        builder: (_, __) => const Tr0100TransactionScreen(),
      ),
      GoRoute(
        path: '/lb0100',
        name: 'LB0100',
        builder: (_, __) => const Lb0100IouScreen(),
      ),

      // ───── プレースホルダルート（未実装画面のための暫定。後で正式Screenに差し替え）
      GoRoute(
        path: '/fr0100',
        name: 'FR0100',
        builder: (context, state) => const _PlaceholderScaffold(title: 'FR0100 ともだち一覧（仮）'),
      ),
      GoRoute(
        path: '/fr0200',
        name: 'FR0200',
        builder: (context, state) => const _PlaceholderScaffold(title: 'FR0200 ともだち詳細（仮）'),
      ),
      GoRoute(
        path: '/my0100',
        name: 'MY0100',
        builder: (context, state) => const _PlaceholderScaffold(title: 'MY0100 じぶん（仮）'),
      ),
      GoRoute(
        path: '/ev0100',
        name: 'EV0100',
        builder: (context, state) => const _PlaceholderScaffold(title: 'EV0100 イベント一覧（仮）'),
      ),
      GoRoute(
        path: '/ev0200',
        name: 'EV0200',
        builder: (context, state) => const _PlaceholderScaffold(title: 'EV0200 イベント詳細（仮）'),
      ),
      GoRoute(
        path: '/sv0100',
        name: 'SV0100',
        builder: (context, state) => const _PlaceholderScaffold(title: 'SV0100 清算結果（仮）'),
      ),
    ],
  );
});

// 画面未実装時の簡易プレースホルダ
class _PlaceholderScaffold extends StatelessWidget {
  const _PlaceholderScaffold({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
