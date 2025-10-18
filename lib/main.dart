import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/presentation/group_make/gr0200Screen.dart';
import 'package:shakuyousho_app/presentation/loan_book/lb0100Screen.dart';
import 'package:shakuyousho_app/presentation/top/to0100Screen.dart';
import 'package:shakuyousho_app/presentation/transaction/tr0100Screen.dart';

import 'presentation/splash/st0100screen.dart';
import 'presentation/group_make/gr0100screen.dart';

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/st0100',
      routes: [
        GoRoute(
          path: '/st0100',
          name: 'ST0100',
          builder: (_, __) => const St0100SplashScreen(),
        ),
        GoRoute(
          path: '/to0100',
          name: 'TO0100',
          builder: (_, __) => const To0100TopScreen(),
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
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(useMaterial3: true),
    );
  }
}
