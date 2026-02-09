import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/core/config/app_flags.dart';
import 'package:shakuyousho_app/core/utils/app_settings.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firestore_collections.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';

class St0200FirstLaunchScreen extends ConsumerStatefulWidget {
  const St0200FirstLaunchScreen({super.key});

  @override
  ConsumerState<St0200FirstLaunchScreen> createState() =>
      _St0200FirstLaunchScreenState();
}

class _St0200FirstLaunchScreenState
    extends ConsumerState<St0200FirstLaunchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = _controller.text.trim();
    return text.isNotEmpty && text.length <= 8;
  }

  Future<void> _onStart() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 8) return;
    final myId = ref.read(currentUserIdProvider);
    final repo = ref.read(userRepositoryProvider);
    final current = repo.getById(myId);
    final updated =
        (current ??
                User(id: myId, displayName: text, createdAt: DateTime.now()))
            .copyWith(displayName: text);
    try {
      repo.upsert(updated);
      if (kUseFirebase) {
        final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
        if (uid == null || uid.isEmpty) {
          throw Exception('ユーザーが取得できません');
        }
        final doc = FirestoreCollections.usersRef().doc(uid);
        final snap = await doc.get();
        final data = <String, dynamic>{
          'displayName': text,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (!snap.exists) {
          data['createdAt'] = FieldValue.serverTimestamp();
        }
        await doc.set(data, SetOptions(merge: true));
      }
      await setFirstLaunchDone();
    } catch (e, st) {
      final err = toAppError(e, st);
      if (!mounted) return;
      await showAppErrorDialog(context: context, error: err);
      return;
    }
    if (!mounted) return;
    context.go('/st0100');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.yellow.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
            child: Column(
              children: [
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryActionFill,
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: AppColors.secondaryActionBorder,
                        ),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: const Icon(
                        Icons.handshake,
                        size: 36,
                        color: AppColors.iconDefault,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'しゃくよーしょ',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: AppTextSizes.amountLarge,
                            fontWeight: AppFontWeights.sectionTitle,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'なまえを おしえてね',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: AppTextSizes.section,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLength: 8,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 22,
                            fontWeight: AppFontWeights.label,
                            color: AppColors.navSelectedIcon,
                          ),
                      decoration: InputDecoration(
                        hintText: 'ここに かく',
                        hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: AppTextSizes.body,
                              color: AppColors.iconDefault,
                            ),
                        counterText: '',
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.listBorder, width: 2),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.navSelectedIcon, width: 2),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '※ 8もじ まで',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: AppTextSizes.small,
                            color: AppColors.iconDefault,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isValid ? _onStart : null,
                    style: AppButtonStyles.primaryPill,
                    child: Text(
                      'はじめる',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.label,
                            color: AppColors.primaryActionText,
                          ),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.iconDefault,
                        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: AppTextSizes.tiny,
                            ),
                      ),
                      child: const Text('りようきやく'),
                    ),
                    Text(
                      '｜',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: AppTextSizes.tiny,
                            color: AppColors.iconDefault.withValues(alpha: 0.5),
                          ),
                    ),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.iconDefault,
                        textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: AppTextSizes.tiny,
                            ),
                      ),
                      child: const Text('ぷらいばしー'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 72,
            child: Icon(
              Icons.spa,
              size: 96,
              color: AppColors.listBorder.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
