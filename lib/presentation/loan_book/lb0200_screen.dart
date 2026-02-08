import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';
import 'package:shakuyousho_app/presentation/common/app_paper_background.dart';
import 'package:shakuyousho_app/presentation/common/strings.dart';

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('とりひき を ついか', style: TextStyle(fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 0),

            // 相手の名前 (label adjusted)
            const Text(
              'かりたひと',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
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
            const Text(
              'きんがく',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              placeholder: '0',
              suffix: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(AppStrings.amountUnit, style: const TextStyle()),
              ),
              style: const TextStyle(fontSize: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // 目的
            const Text(
              'ようけん',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _purposeController,
              placeholder: 'ごはんだい など',
              style: const TextStyle(fontSize: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // 備考
            const Text(
              'びこう',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _noteController,
              placeholder: 'めもなど（にんい）',
              style: const TextStyle(fontSize: 16),
              maxLines: 3,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 24),

            // 返済期限
            const Text(
              'めやすのひ',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      _fmtDate(_dueDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(
                      CupertinoIcons.calendar,
                      color: Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 送るボタン（LB0100 と同様の UI）
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _onSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'おくる',
                    style: TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
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
    final loansAsync = ref.watch(allLoansProvider);

    return loansAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFFFF8DC),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
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
            ),
            body: const Center(
              child: Text('とりひき が みつかりません', style: TextStyle()),
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
            title: const Text(
              'しゃくよーしょ 詳細',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
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
                      const Text(
                        'かりたひと',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78716C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        borrowerName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF44403C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // きんがく
                  Column(
                    children: [
                      const Text(
                        'きんがく',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78716C),
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
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: amountColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _fmtYen(loan.amountYen),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              color: amountColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '-',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: amountColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DetailTextBlock(
                    label: 'ようと',
                    value: loan.purpose.isEmpty ? 'なし' : loan.purpose,
                  ),
                  _DetailTextBlock(
                    label: 'へんさい きげん',
                    value: _fmtDateJa(loan.dueDate),
                  ),
                  _DetailTextBlock(
                    label: 'つくったひ',
                    value: _fmtDateJa(loan.createdAt),
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
                      const Text(
                        'かしたひと',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78716C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lenderName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF44403C),
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
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      child: const Text('とじる'),
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
                          child: const Text('やめる'),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        const Text(
                          'めやすのひ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Text('けってい'),
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

  void _onSave() {
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

    // 友達をまず追加（存在チェックはrepositoryで行う）
    ref.read(friendActionsProvider.notifier).addFriend(resolvedId);

    // ローン作成
    ref
        .read(loanActionsProvider.notifier)
        .createLoan(
          counterpartyId: resolvedId,
          amountYen: amount,
          purpose: purpose,
          note: _noteController.text.trim(),
          dueDate: _dueDate,
        );

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
        title: const Text('エラー', style: TextStyle()),
        content: Text(msg, style: const TextStyle()),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Loan loan) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('さくじょ', style: TextStyle()),
        content: const Text('この とりひき を けしますか？', style: TextStyle()),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: false,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる', style: TextStyle()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('けす', style: TextStyle()),
          ),
        ],
      ),
    );

    if (ok == true) {
      ref.read(loanActionsProvider.notifier).deleteLoan(loan.id);
      if (context.mounted) context.pop();
    }
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
    return CupertinoTextField(
      controller: TextEditingController(text: initialValue),
      placeholder: placeholder,
      style: const TextStyle(fontSize: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      onChanged: onChanged,
    );
  }
}

/// 詳細行
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(width: 12),
          if (child != null) child!,
          if (value != null)
            Expanded(
              child: Text(
                value!,
                style: const TextStyle(fontSize: 16, color: Color(0xFF111827)),
              ),
            ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF78716C)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: mono ? 14 : 18,
              fontWeight: mono ? FontWeight.w500 : FontWeight.w600,
              color: const Color(0xFF44403C),
              fontFamily: mono ? 'monospace' : null,
              letterSpacing: mono ? 1.6 : 0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ユーティリティ関数
String _fmtYen(int value) {
  final s = value.toString();
  return s.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

String _fmtDate(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}/${two(dt.month)}/${two(dt.day)}';
}

String _fmtDateJa(DateTime dt) {
  return '${dt.year}ねん ${dt.month}がつ ${dt.day}にち';
}

String _fmtDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}
