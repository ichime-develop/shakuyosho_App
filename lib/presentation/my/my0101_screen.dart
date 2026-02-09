import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/core/config/app_flags.dart';
import 'package:shakuyousho_app/infrastructure/firestore/firebase_user_sync_service.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';

class My0101NameEditScreen extends ConsumerStatefulWidget {
  const My0101NameEditScreen({super.key});

  @override
  ConsumerState<My0101NameEditScreen> createState() =>
      _My0101NameEditScreenState();
}

class _My0101NameEditScreenState extends ConsumerState<My0101NameEditScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final current = ref.read(currentUserProvider);
    _controller = TextEditingController(text: current?.displayName ?? '');
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

  Future<void> _onSave() async {
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
        await const FirebaseUserSyncService().syncCurrentUser(updated);
      }
    } catch (e, st) {
      final err = toAppError(e, st);
      if (!mounted) return;
      await showAppErrorDialog(context: context, error: err);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'なまえをへんしゅう',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: AppTextSizes.title,
                fontWeight: AppFontWeights.appBarTitle,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLength: 8,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: AppTextSizes.body,
                  ),
              decoration: InputDecoration(
                hintText: 'なまえをいれてね',
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: AppTextSizes.small,
                      color: AppColors.iconDefault,
                    ),
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  borderSide: const BorderSide(color: AppColors.listBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  borderSide: const BorderSide(color: AppColors.listBorder),
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
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: AppButtonStyles.secondaryPill,
                    child: Text(
                      'もどる',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.label,
                            color: AppColors.secondaryActionText,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isValid ? _onSave : null,
                    style: AppButtonStyles.primaryPill,
                    child: Text(
                      'ほぞん',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.label,
                            color: AppColors.primaryActionText,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
