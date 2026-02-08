import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shakuyousho_app/application/providers/friend_providers.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';

/// FR0100 から呼ばれるともだち追加 BottomSheet を表示する。
///
/// 戻り値が `'qr'` の場合、呼び出し側で QR スキャナー画面に遷移する。
Future<String?> showAddFriendSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AddFriendSheet(),
  );
}

// ────────────────────────────────────────────────────────────────
// BottomSheet 本体
// ────────────────────────────────────────────────────────────────

class _AddFriendSheet extends ConsumerStatefulWidget {
  const _AddFriendSheet();

  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet> {
  final _codeController = TextEditingController();
  bool _processing = false;
  String? _resultMessage;
  bool _resultIsError = false;
  bool _copied = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final myCode = currentUser?.myCode ?? '---';
    final inviteUrl = 'shakuyousho://invite?code=$myCode';
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ドラッグハンドル
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // タイトル
              Center(
                child: Text(
                  'ともだち を ついか',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: AppTextSizes.title,
                    fontWeight: AppFontWeights.appBarTitle,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── セクション 1: コードで追加 ──────────────
              const _SectionTitle(icon: Icons.edit, label: 'コードで ついか'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _codeController,
                      placeholder: 'SYY-XXXXX',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: AppTextSizes.body,
                      ),
                      placeholderStyle: theme.textTheme.bodySmall?.copyWith(
                        fontSize: AppTextSizes.small,
                        color: AppColors.iconDefault,
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: _processing ? null : _onAddByCode,
                      style: AppButtonStyles.primaryPill,
                      child: Text(
                        'ついか',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: AppTextSizes.body,
                          fontWeight: AppFontWeights.label,
                          color: AppColors.primaryActionText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_resultMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _resultMessage!,
                  style: TextStyle(
                    fontSize: AppTextSizes.small,
                    color: _resultIsError
                        ? Colors.red.shade600
                        : AppColors.primaryActionFill,
                    fontWeight: AppFontWeights.listSubtitle,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── セクション 2: QR で追加 ──────────────
              const _SectionTitle(
                icon: Icons.qr_code_scanner,
                label: 'QR で ついか',
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop('qr'),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('QR コードを よみとる'),
                  style: AppButtonStyles.secondaryPill,
                ),
              ),
              const SizedBox(height: 24),

              // ── セクション 3: じぶんのコード ──────────────
              const _SectionTitle(
                icon: Icons.person_outline,
                label: 'じぶんの コード',
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      // QR コード
                      QrImageView(
                        data: inviteUrl,
                        version: QrVersions.auto,
                        size: 160,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF111827),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // コード文字
                      SelectableText(
                        myCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: AppTextSizes.title,
                          fontWeight: AppFontWeights.listTitle,
                          letterSpacing: 2,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // コピー・共有ボタン
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: _onCopy,
                            icon: Icon(
                              _copied ? Icons.check : Icons.copy,
                              size: 18,
                            ),
                            label: Text(_copied ? 'コピーしました' : 'コピー'),
                            style: TextButton.styleFrom(
                              foregroundColor: _copied
                                  ? AppColors.primaryActionFill
                                  : AppColors.iconDefault,
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              await Share.share(
                                'しゃくようしょ で ともだちに なろう！\n$inviteUrl',
                              );
                            },
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('きょうゆう'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.iconDefault,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── コードで追加 ──────────────────────────────────────

  Future<void> _onAddByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _processing = true;
      _resultMessage = null;
    });

    final result = await ref
        .read(friendActionsProvider.notifier)
        .addFriendByCode(code, source: 'code');

    if (!mounted) return;

    setState(() {
      _processing = false;
      switch (result) {
        case AddFriendResult.success:
          _resultMessage = 'ともだちに なりました！';
          _resultIsError = false;
          _codeController.clear();
        case AddFriendResult.notFound:
          _resultMessage = 'みつかりません';
          _resultIsError = true;
        case AddFriendResult.selfAdd:
          _resultMessage = 'じぶんの コードです';
          _resultIsError = true;
        case AddFriendResult.alreadyFriend:
          _resultMessage = 'すでに ともだちです';
          _resultIsError = true;
      }
    });
  }

  // ── コピー ────────────────────────────────────────────

  Future<void> _onCopy() async {
    final myCode = ref.read(currentUserProvider)?.myCode ?? '';
    await Clipboard.setData(ClipboardData(text: myCode));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }
}

// ────────────────────────────────────────────────────────────────
// セクション見出し
// ────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.iconDefault),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: AppTextSizes.body,
            fontWeight: AppFontWeights.sectionTitle,
            color: AppColors.iconDefault,
          ),
        ),
      ],
    );
  }
}
