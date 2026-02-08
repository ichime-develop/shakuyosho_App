import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';
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
            // かす（固定）
            const Text(
              'しゅべつ',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'かす',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 24),

            // 相手の名前
            const Text(
              'あいて',
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

            // 保存ボタン
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: const Color(0xFF4F46E5),
                borderRadius: BorderRadius.circular(12),
                onPressed: _onSave,
                child: const Text(
                  'ほぞん',
                  style: TextStyle(fontSize: 18, color: Colors.white),
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

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('しょうさい', style: TextStyle(fontSize: 18)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.trash),
                tooltip: 'さくじょ',
                onPressed: () => _confirmDelete(context, loan),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 状態
              _DetailRow(
                label: 'じょうたい',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: loan.isRepaid
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    loan.isRepaid ? 'へんさいずみ' : 'みへんさい',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: loan.isRepaid
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 相手
              _DetailRow(label: 'あいて', value: _resolveDisplayName(loan)),
              const SizedBox(height: 16),
              // 金額
              _DetailRow(label: 'きんがく', value: '¥${_fmtYen(loan.amountYen)}'),
              const SizedBox(height: 16),
              // 目的
              _DetailRow(label: 'ようけん', value: loan.purpose),
              const SizedBox(height: 16),
              // 備考
              if (loan.note.isNotEmpty) ...[                _DetailRow(label: 'びこう', value: loan.note),
                const SizedBox(height: 16),
              ],
              // めやすのひ
              _DetailRow(label: 'めやすのひ', value: _fmtDate(loan.dueDate)),
              const SizedBox(height: 16),
              // 作成日
              _DetailRow(label: 'つくったひ', value: _fmtDateTime(loan.createdAt)),
              const SizedBox(height: 16),
              // 借用証番号
              _DetailRow(label: 'しゃくようしょう No.', value: loan.iouNo),

              // 返済履歴
              if (loan.repayments.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'へんさい りれき',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                ...loan.repayments.map(
                  (r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmtDate(r.paidAt), style: const TextStyle()),
                        Text(
                          '¥${_fmtYen(r.amountYen)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 残額
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: loan.isRepaid
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loan.isRepaid ? 'かんさい！' : 'のこり',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '¥${_fmtYen(loan.remainingYen)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
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

  String _resolveDisplayName(Loan loan) {
    final userRepo = ref.read(userRepositoryProvider);
    return userRepo.getById(loan.counterpartyId)?.displayName ??
        loan.counterpartyId;
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

String _fmtDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year}/${two(dt.month)}/${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
}
