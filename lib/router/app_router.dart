import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/core/utils/route_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/presentation/loan_book/lb0100_screen.dart';
import 'package:shakuyousho_app/presentation/transaction/tr0100_screen.dart';
import 'package:shakuyousho_app/presentation/top/to0100_screen.dart';
import 'package:shakuyousho_app/presentation/friends/fr0100_screen.dart';
import 'package:shakuyousho_app/presentation/friends/fr0200_screen.dart';
import 'package:shakuyousho_app/presentation/my/my0100_screen.dart';
import 'package:shakuyousho_app/presentation/event/ev0100_screen.dart';
import 'package:shakuyousho_app/presentation/event/ev0200_screen.dart';
import 'package:shakuyousho_app/presentation/settlement/sv0100_screen.dart';

import '../presentation/splash/st0100_screen.dart';
import '../presentation/event/ev0101_screen.dart';

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
        path: '/ev0101',
        name: 'EV0101',
        builder: (_, __) => const Ev0101EventCreateScreen(),
      ),
      GoRoute(
        path: '/tr0100/:eventId',
        name: 'TR0100',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'];
          if (eventId == null || eventId.isEmpty) {
            return const _MissingParamScreen(
              param: 'eventId',
              screen: 'TR0100',
            );
          }
          final transactionId = state.uri.queryParameters['transactionId'];
          final mode = state.uri.queryParameters['mode'];
          return Tr0100TransactionScreen(
            eventId: eventId,
            transactionId: transactionId,
          );
        },
      ),
      GoRoute(
        path: '/lb0100/:friendId',
        name: 'LB0100',
        builder: (context, state) {
          final friendId = state.pathParameters['friendId'];
          if (friendId == null || friendId.isEmpty) {
            return const _MissingParamScreen(
              param: 'friendId',
              screen: 'LB0100',
            );
          }
          return Lb0100IouScreen(friendId: friendId);
        },
      ),

      // ───── プレースホルダルート（未実装画面のための暫定。後で正式Screenに差し替え）
      GoRoute(
        path: '/fr0100',
        name: 'FR0100',
        builder: (context, state) => const Fr0100FriendsScreen(),
      ),
      GoRoute(
        path: '/fr0200/:friendId',
        name: 'FR0200',
        builder: (context, state) {
          final friendId = state.pathParameters['friendId'];
          if (friendId == null || friendId.isEmpty) {
            return const _MissingParamScreen(
              param: 'friendId',
              screen: 'FR0200',
            );
          }
          return Fr0200FriendDetailScreen(friendId: friendId);
        },
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
        path: '/ev0200/:eventId',
        name: 'EV0200',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return Ev0200EventDetailScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/sv0100/:eventId',
        name: 'SV0100',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId'];
          if (eventId == null || eventId.isEmpty) {
            return const _MissingParamScreen(
              param: 'eventId',
              screen: 'SV0100',
            );
          }
          return Sv0100SettlementScreen(eventId: eventId);
        },
      ),
    ],
  );
});

/// パラメータ未指定時のエラー画面
class _MissingParamScreen extends StatelessWidget {
  const _MissingParamScreen({required this.param, required this.screen});
  final String param;
  final String screen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$screen エラー')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '必須パラメータ「$param」が指定されていません',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/to0100/personal'),
              child: const Text('ホームへ戻る'),
            ),
          ],
        ),
      ),
    );
  }
}

// Note: placeholder scaffold removed — routes now point to real screens or placeholders in presentation/.
