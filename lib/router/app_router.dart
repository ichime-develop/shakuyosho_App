import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/core/utils/route_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/presentation/loan_book/lb0100Screen.dart';
import 'package:shakuyousho_app/presentation/transaction/tr0100Screen.dart';
import 'package:shakuyousho_app/presentation/top/to0100Screen.dart';
import 'package:shakuyousho_app/presentation/friends/fr0100Screen.dart';
import 'package:shakuyousho_app/presentation/friends/fr0200Screen.dart';
import 'package:shakuyousho_app/presentation/my/my0100Screen.dart';
import 'package:shakuyousho_app/presentation/event/ev0100Screen.dart';
import 'package:shakuyousho_app/presentation/event/ev0200Screen.dart';
import 'package:shakuyousho_app/presentation/settlement/sv0100Screen.dart';

import '../presentation/splash/st0100screen.dart';
import '../presentation/group_make/gr0100screen.dart';
import '../presentation/group_make/gr0200Screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    observers: ref.read(goRouterObserversProvider),
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

      // TO0100: 統一ルート（タブは path parameter によって制御）
      GoRoute(
        path: '/to0100',
        name: 'TO0100',
        redirect: (context, state) => '/to0100/personal',
      ),
      GoRoute(
        path: '/to0100/:tab(personal|event)',
        name: 'TO0100_TAB',
        pageBuilder: (context, state) {
          final tab = state.pathParameters['tab'];
          final initial = (tab == 'event') ? 1 : 0;
          return NoTransitionPage(
            key: const ValueKey('TO0100'),
            child: To0100Screen(initialTab: initial),
          );
        },
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
        builder: (context, state) => const Fr0100FriendsScreen(),
      ),
      GoRoute(
        path: '/fr0200',
        name: 'FR0200',
        builder: (context, state) => const Fr0200FriendDetailScreen(),
      ),
      GoRoute(
        path: '/my0100',
        name: 'MY0100',
        builder: (context, state) => const My0100Screen(),
      ),
      GoRoute(
        path: '/ev0100',
        name: 'EV0100',
        builder: (context, state) => const Ev0100EventListScreen(),
      ),
      GoRoute(
        path: '/ev0200',
        name: 'EV0200',
        builder: (context, state) => const Ev0200EventDetailScreen(),
      ),
      GoRoute(
        path: '/sv0100',
        name: 'SV0100',
        builder: (context, state) => const Sv0100SettlementScreen(),
      ),
    ],
  );
});

// Note: placeholder scaffold removed — routes now point to real screens or placeholders in presentation/.
