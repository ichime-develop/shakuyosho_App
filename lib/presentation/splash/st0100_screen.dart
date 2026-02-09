import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/core/config/app_flags.dart';
import 'package:shakuyousho_app/core/utils/app_settings.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firebase_user_sync_service.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';

class St0100SplashScreen extends ConsumerStatefulWidget {
  const St0100SplashScreen({super.key});
  @override
  ConsumerState<St0100SplashScreen> createState() => _St0100SplashScreenState();
}

class _St0100SplashScreenState extends ConsumerState<St0100SplashScreen> {
  bool _didShowError = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      if (kUseFirebase) {
        final auth = firebase_auth.FirebaseAuth.instance;
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
        }

        final userRepo = ref.read(userRepositoryProvider);
        final myId = ref.read(currentUserIdProvider);
        final localUser = userRepo.getById(myId);
        final syncService = const FirebaseUserSyncService();
        final remoteUser = await syncService.fetchCurrentUser(
          fallbackAppUserId: myId,
          fallbackDisplayName: localUser?.displayName ?? 'あなた',
        );

        if (remoteUser != null) {
          final merged =
              (localUser ??
                      User(
                        id: myId,
                        displayName: remoteUser.displayName,
                        createdAt: DateTime.now(),
                      ))
                  .copyWith(
                    displayName: remoteUser.displayName,
                    myCode: remoteUser.myCode ?? localUser?.myCode,
                    avatarUrl: remoteUser.avatarUrl ?? localUser?.avatarUrl,
                  );
          userRepo.upsert(merged);
        } else if (localUser != null) {
          await syncService.syncCurrentUser(localUser);
        }
      }
      // TODO: 起動時の初期データ取得（Firebase移行時にここへ追加）
      final firstLaunch = isFirstLaunch();
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      if (firstLaunch) {
        context.go('/st0200');
        return;
      }
      context.go('/to0100');
    } catch (e, st) {
      if (_didShowError) return;
      _didShowError = true;
      if (!mounted) return;
      final err = toAppError(e, st);
      await showAppErrorDialog(context: context, error: err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('ST0100 スプラッシュ（かり）')),
    );
  }
}
