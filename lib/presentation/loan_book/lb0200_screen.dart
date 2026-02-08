import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/core/extensions/date_time_extension.dart';
import 'package:shakuyousho_app/core/extensions/num_extension.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';
import 'package:shakuyousho_app/presentation/common/app_paper_background.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/app_loading_screen.dart';
import 'package:shakuyousho_app/presentation/common/strings.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import 'package:shakuyousho_app/presentation/common/error/app_message_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';

/// LB0200: 取引の追加と編集（坂口モデル準拠）
///
/// 2つのモード:
/// - 新規作成: loanId == null, friendId != null
/// - 詳細表示: loanId != null
class Lb0200BorrowNotePreviewScreen extends ConsumerStatefulWidget {
  const Lb0200BorrowNotePreviewScreen({super.key, this.loanId, this.friendId});

  final String? loanId;
  final String? friendId;

  @override
  ConsumerState<Lb0200BorrowNotePreviewScreen> createState() =>
      _Lb0200ScreenState();
}

class _Lb0200ScreenState extends ConsumerState<Lb0200BorrowNotePreviewScreen> {
  bool get isCreating => widget.loanId == null;
  bool _didShowReadError = false;

  // 新規作成用フォーム
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _friendId = '';
  String _friendInput = '';

  @override
  void initState() {
    super.initState();
    _friendId = widget.friendId ?? '';
    if (_friendId.isNotEmpty) {
      final userRepo = ref.read(userRepositoryProvider);
      _friendInput = userRepo.getById(_friendId)?.displayName ?? _friendId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isCreating) {
      return _buildCreateMode(context);
    } else {
      return _buildDetailMode(context);
    }
  }

  /// 新規作成モード
  Widget _buildCreateMode(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: AppTextSizes.small,
      color: AppColors.iconDefault,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'しゃくよーしょ さくせい',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: AppTextSizes.title,
            fontWeight: AppFontWeights.appBarTitle,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 0),

            // 相手の名前 (label adjusted)
            Text('かりたひと', style: labelStyle),
            const SizedBox(height: 8),
            _InputField(
              initialValue: _friendInput,
              placeholder: 'ユーザーID / なまえ',
              onChanged: (v) {
                _friendInput = v;
                _friendId = '';
              },
            ),
            const SizedBox(height: 24),

            // 金額
            Text('きんがく', style: labelStyle),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              placeholder: '0',
              suffix: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  AppStrings.amountUnit,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: AppTextSizes.small,
                    color: AppColors.iconDefault,
                  ),
                ),
              ),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: AppTextSizes.amountLarge,
                fontWeight: AppFontWeights.listTitle,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.listBorder),
              ),
            ),
            const SizedBox(height: 24),

            // 目的
            Text('ようけん', style: labelStyle),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _purposeController,
              placeholder: 'ごはんだい など',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppTextSizes.body,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.listBorder),
              ),
            ),
            const SizedBox(height: 24),

            // 備考
            Text('びこう', style: labelStyle),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _noteController,
              placeholder: 'めもなど（にんい）',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppTextSizes.body,
              ),
              maxLines: 3,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.listBorder),
              ),
            ),
            const SizedBox(height: 24),

            // 返済期限
            Text('きげん', style: labelStyle),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: AppColors.listBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      _dueDate.toYmdSlash(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: AppTextSizes.body,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      CupertinoIcons.calendar,
                      color: AppColors.iconDefault,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 送るボタン（既存の借用書UIと同様）
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                style: AppButtonStyles.primaryPill,
                child: Text(
                  'おくる',
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
      ),
    );
  }

  /// 詳細表示モード
  Widget _buildDetailMode(BuildContext context) {
    final theme = Theme.of(context);
    final loansAsync = ref.watch(allLoansProvider);

    return loansAsync.when(
      loading: () => const AppLoadingScreen(),
      error: (e, st) {
        _handleReadError(e, st);
        return Scaffold(
          body: Center(
            child: Text(
              AppMessages.dialog(AppMessageId.s004).message,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: AppTextSizes.small,
                color: AppColors.iconDefault,
              ),
            ),
          ),
        );
      },
      data: (loans) {
        final loan = loans.firstWhere(
          (l) => l.id == widget.loanId,
          orElse: () => Loan.empty(),
        );

        if (loan.id.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Text(
                'とりひき が みつかりません',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: AppTextSizes.small,
                  color: AppColors.iconDefault,
                ),
              ),
            ),
          );
        }

        final borrowerName = _displayNameOf(loan.borrowerUserId);
        final lenderName = _displayNameOf(loan.lenderUserId);
        final amountColor = const Color(0xFF475569);

        return Scaffold(
          backgroundColor: AppPaperBackground.baseColor,
          appBar: AppBar(
            backgroundColor: AppPaperBackground.baseColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'しゃくよーしょ しょうさい',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: AppTextSizes.title,
                fontWeight: AppFontWeights.appBarTitle,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.trash),
                tooltip: 'さくじょ',
                onPressed: () => _confirmDelete(context, loan),
              ),
            ],
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
                children: [
                  // かりたひと
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'かりたひと',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: AppTextSizes.small,
                          color: const Color(0xFF78716C),
                          fontWeight: AppFontWeights.listSubtitle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        borrowerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: AppTextSizes.amountLarge,
                          fontWeight: AppFontWeights.listTitle,
                          color: const Color(0xFF44403C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // きんがく
                  Column(
                    children: [
                      Text(
                        'きんがく',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: AppTextSizes.small,
                          color: const Color(0xFF78716C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '¥',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: AppTextSizes.amountXL,
                              fontWeight: AppFontWeights.listTitle,
                              color: amountColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            loan.amountYen.toCommaString(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: AppTextSizes.amountXXL,
                              fontWeight: AppFontWeights.listTitle,
                              letterSpacing: -1,
                              color: amountColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '-',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontSize: AppTextSizes.section,
                              fontWeight: AppFontWeights.listTitle,
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DetailTextBlock(
                    label: 'のこり',
                    value: loan.remainingYen.toYenSymbol(),
                  ),
                  if (loan.repayments.isNotEmpty)
                    _DetailTextBlock(
                      label: 'へんさい',
                      value:
                          '${loan.repaidYen.toYenSymbol()} / ${loan.amountYen.toYenSymbol()}',
                    ),
                  if (loan.remainingYen == 0)
                    const _DetailTextBlock(label: 'じょうたい', value: 'しはらいかんりょう'),
                  _DetailTextBlock(
                    label: 'ようと',
                    value: loan.purpose.isEmpty ? 'なし' : loan.purpose,
                  ),
                  _DetailTextBlock(
                    label: 'へんさい きげん',
                    value: loan.dueDate.toYmdJa(),
                  ),
                  _DetailTextBlock(
                    label: 'つくったひ',
                    value: loan.createdAt.toYmdJa(),
                  ),
                  _DetailTextBlock(
                    label: 'ばんごう',
                    value: loan.iouNo,
                    mono: true,
                  ),
                  _DetailTextBlock(
                    label: 'びこうらん',
                    value: loan.note.isEmpty ? 'なし' : loan.note,
                  ),
                  const SizedBox(height: 12),
                  // かしたひと
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'かしたひと',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: AppTextSizes.small,
                          color: const Color(0xFF78716C),
                          fontWeight: AppFontWeights.listSubtitle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lenderName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: AppTextSizes.section,
                          fontWeight: AppFontWeights.listTitle,
                          color: const Color(0xFF44403C),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Color(0xFFFFF8DC),
                        Color(0xFFFFF8DC),
                        Color(0x00FFF8DC),
                      ],
                    ),
                  ),
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.iconDefault,
                        side: const BorderSide(color: AppColors.listBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                      ),
                      child: Text(
                        'とじる',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: AppTextSizes.body,
                          fontWeight: AppFontWeights.label,
                          color: AppColors.iconDefault,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleReadError(Object error, StackTrace stackTrace) {
    if (_didShowReadError) return;
    _didShowReadError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final err = toAppError(error, stackTrace);
      await showAppErrorDialog(context: context, error: err);
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime temp = _dueDate;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;
        return Material(
          color: Colors.transparent,
          child: Container(
            height: 320 + bottomPad,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8DC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'やめる',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  fontSize: AppTextSizes.small,
                                ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        Text(
                          'きげん',
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                fontSize: AppTextSizes.small,
                                fontWeight: AppFontWeights.listSubtitle,
                                color: AppColors.iconDefault,
                              ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'けってい',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                  fontSize: AppTextSizes.small,
                                ),
                          ),
                          onPressed: () {
                            setState(() => _dueDate = temp);
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Localizations.override(
                      context: ctx,
                      locale: const Locale('ja', 'JP'),
                      child: CupertinoDatePicker(
                        backgroundColor: const Color(0xFFFFF8DC),
                        initialDateTime: _dueDate,
                        minimumDate: DateTime.now(),
                        maximumDate: DateTime(2100),
                        mode: CupertinoDatePickerMode.date,
                        dateOrder: DatePickerDateOrder.ymd,
                        onDateTimeChanged: (d) => temp = d,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onSave() async {
    final amount = int.tryParse(_amountController.text.trim());
    final purpose = _purposeController.text.trim();
    final input = _friendInput.trim();

    if (amount == null || amount <= 0) {
      _showError('きんがく を いれてね');
      return;
    }
    if (input.isEmpty) {
      _showError('あいて を いれてね');
      return;
    }
    if (purpose.isEmpty) {
      _showError('ようけん を いれてね');
      return;
    }

    final userRepo = ref.read(userRepositoryProvider);
    String? resolvedId;
    if (_friendId.isNotEmpty) {
      final displayName = userRepo.getById(_friendId)?.displayName;
      if (input == _friendId || input == displayName) {
        resolvedId = _friendId;
      }
    }
    resolvedId ??= userRepo.getById(input)?.id;
    if (resolvedId == null) {
      for (final user in userRepo.getAll()) {
        if (user.displayName == input) {
          resolvedId = user.id;
          break;
        }
      }
    }
    if (resolvedId == null || resolvedId.isEmpty) {
      _showError('ユーザーが みつかりません');
      return;
    }

    // 友達追加と借用書作成はまとめてエラーハンドリング
    try {
      await ref.read(friendActionsProvider.notifier).addFriend(resolvedId);
      await ref
          .read(loanActionsProvider.notifier)
          .createLoan(
            counterpartyId: resolvedId,
            amountYen: amount,
            purpose: purpose,
            note: _noteController.text.trim(),
            dueDate: _dueDate,
          );
    } catch (e, st) {
      final err = toAppError(e, st);
      if (!mounted) return;
      await showAppErrorDialog(context: context, error: err);
      return;
    }

    if (!mounted) return;
    context.pop();
  }

  String _displayNameOf(String userId) {
    if (userId.isEmpty) return '';
    final userRepo = ref.read(userRepositoryProvider);
    return userRepo.getById(userId)?.displayName ?? userId;
  }

  void _showError(String msg) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          'エラー',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: AppTextSizes.body,
            fontWeight: AppFontWeights.listTitle,
          ),
        ),
        content: Text(
          msg,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: AppTextSizes.small,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: AppTextSizes.small,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Loan loan) async {
    await showAppMessageDialog(
      context: context,
      messageId: AppMessageId.lb0200_001,
      closeOnDestructiveSuccess: false,
      onDestructive: () async {
        await ref.read(loanActionsProvider.notifier).deleteLoan(loan.id);
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        context.pop();
      },
    );
  }
}

/// テキストフィールド
class _InputField extends StatelessWidget {
  const _InputField({
    required this.placeholder,
    this.initialValue = '',
    this.onChanged,
  });

  final String placeholder;
  final String initialValue;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CupertinoTextField(
      controller: TextEditingController(text: initialValue),
      placeholder: placeholder,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: AppTextSizes.body,
      ),
      placeholderStyle: theme.textTheme.bodySmall?.copyWith(
        fontSize: AppTextSizes.small,
        color: AppColors.iconDefault,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.listBorder),
      ),
      onChanged: onChanged,
    );
  }
}


/// 詳細テキストブロック（スクリーン寄せ）
class _DetailTextBlock extends StatelessWidget {
  const _DetailTextBlock({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: AppTextSizes.small,
              color: const Color(0xFF78716C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: mono ? AppTextSizes.body : AppTextSizes.title,
              fontWeight: mono
                  ? AppFontWeights.listSubtitle
                  : AppFontWeights.listTitle,
              color: const Color(0xFF44403C),
              letterSpacing: mono ? 1.2 : 0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ユーティリティ関数
