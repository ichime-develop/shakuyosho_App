import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/core/utils/route_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/presentation/loan_book/lb0100_screen.dart';
import 'package:shakuyousho_app/presentation/transaction/tr0100_screen.dart';
import 'package:shakuyousho_app/presentation/top/to0100_screen.dart';
import 'package:shakuyousho_app/presentation/friends/fr0100_screen.dart';
import 'package:shakuyousho_app/presentation/friends/fr0200_screen.dart';
import 'package:shakuyousho_app/presentation/loan_book/lb0200_screen.dart';
import 'package:shakuyousho_app/presentation/my/my0100_screen.dart';
import 'package:shakuyousho_app/presentation/my/my0101_screen.dart';
import 'package:shakuyousho_app/presentation/event/ev0100_screen.dart';
import 'package:shakuyousho_app/presentation/event/ev0200_screen.dart';
import 'package:shakuyousho_app/presentation/settlement/sv0100_screen.dart';
import 'package:shakuyousho_app/presentation/common/app_route_loading_gate.dart';

import '../presentation/splash/st0100_screen.dart';
import '../presentation/event/ev0101_screen.dart';
import '../presentation/friends/invite_screen.dart';
import '../presentation/friends/qr_scanner_screen.dart';

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
      // ── 招待リンク（shakuyousho://invite?code=...）
      GoRoute(
        path: '/invite',
        name: 'INVITE',
        pageBuilder: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          if (code.isEmpty) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const _MissingParamScreen(param: 'code', screen: 'INVITE'),
            );
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: InviteScreen(code: code),
          );
        },
      ),

      // ── QR スキャナー（BottomSheet から遷移）
      GoRoute(
        path: '/qr-scanner',
        name: 'QR_SCANNER',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const QrScannerScreen(),
        ),
      ),

      GoRoute(
        path: '/st0100',
        name: 'ST0100',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const St0100SplashScreen(),
        ),
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
            key: state.pageKey,
            child: To0100Screen(initialTab: initial),
          );
        },
      ),

      GoRoute(
        path: '/ev0101',
        name: 'EV0101',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const Ev0101EventCreateScreen(),
        ),
      ),
      GoRoute(
        path: '/tr0100/:eventId',
        name: 'TR0100',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'];
          if (eventId == null || eventId.isEmpty) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const _MissingParamScreen(
                param: 'eventId',
                screen: 'TR0100',
              ),
            );
          }
          final transactionId = state.uri.queryParameters['transactionId'];
          return NoTransitionPage(
            key: state.pageKey,
            child: AppRouteLoadingGate(
              // TODO: 外部データ取得を導入したら、ここで prefetch Future を待つ
              // 例) load: () => ref.read(trDetailProvider(...).future),
              load: () async {},
              child: Tr0100TransactionScreen(
                eventId: eventId,
                transactionId: transactionId,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/lb0100/:friendId',
        name: 'LB0100',
        pageBuilder: (context, state) {
          final friendId = state.pathParameters['friendId'];
          if (friendId == null || friendId.isEmpty) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const _MissingParamScreen(
                param: 'friendId',
                screen: 'LB0100',
              ),
            );
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: AppRouteLoadingGate(
              // TODO: 外部データ取得を導入したら、ここで prefetch Future を待つ
              load: () async {},
              child: Lb0100IouScreen(friendId: friendId),
            ),
          );
        },
      ),
      GoRoute(
        path: '/lb0200/:loanId',
        name: 'LB0200_DETAIL',
        pageBuilder: (context, state) {
          final loanId = state.pathParameters['loanId'];
          if (loanId == null || loanId.isEmpty) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const _MissingParamScreen(
                param: 'loanId',
                screen: 'LB0200',
              ),
            );
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: AppRouteLoadingGate(
              load: () async {},
              child: Lb0200BorrowNotePreviewScreen(loanId: loanId),
            ),
          );
        },
      ),
      GoRoute(
        path: '/lb0200',
        name: 'LB0200',
        pageBuilder: (context, state) {
          final friendId = state.uri.queryParameters['friendId'];
          return NoTransitionPage(
            key: state.pageKey,
            child: AppRouteLoadingGate(
              load: () async {},
              child: Lb0200BorrowNotePreviewScreen(friendId: friendId),
            ),
          );
        },
      ),
      GoRoute(
        path: '/fr0100',
        name: 'FR0100',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const Fr0100ThreadListScreen(),
        ),
      ),
      GoRoute(
        path: '/fr0200/:friendId',
        name: 'FR0200',
        pageBuilder: (context, state) {
          final friendId = state.pathParameters['friendId'];
          if (friendId == null || friendId.isEmpty) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const _MissingParamScreen(
                param: 'friendId',
                screen: 'FR0200',
              ),
            );
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: AppRouteLoadingGate(
              load: () async {},
              child: Fr0200ThreadDetailScreen(friendId: friendId),
            ),
          );
        },
      ),
      GoRoute(
        path: '/my0100',
        name: 'MY0100',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const My0100Screen()),
      ),
      GoRoute(
        path: '/my0101',
        name: 'MY0101',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const My0101NameEditScreen(),
        ),
      ),
      GoRoute(
        path: '/ev0100',
        name: 'EV0100',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const Ev0100EventListScreen(),
        ),
      ),
      GoRoute(
        path: '/ev0200/:eventId',
        name: 'EV0200',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return NoTransitionPage(
            key: state.pageKey,
            child: AppRouteLoadingGate(
              // TODO: 外部データ取得を導入したら、ここで prefetch Future を待つ
              load: () async {},
              child: Ev0200EventDetailScreen(eventId: eventId),
            ),
          );
        },
      ),
      GoRoute(
        path: '/sv0100/:eventId',
        name: 'SV0100',
        pageBuilder: (context, state) {
          final eventId = state.pathParameters['eventId'];
          if (eventId == null || eventId.isEmpty) {
            return NoTransitionPage(
              key: state.pageKey,
              child: const _MissingParamScreen(
                param: 'eventId',
                screen: 'SV0100',
              ),
            );
          }
          return NoTransitionPage(
            key: state.pageKey,
            child: AppRouteLoadingGate(
              // TODO: 外部データ取得を導入したら、ここで prefetch Future を待つ
              load: () async {},
              child: Sv0100SettlementScreen(eventId: eventId),
            ),
          );
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
