import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/domain/models/transaction_model.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/strings.dart';
import 'package:shakuyousho_app/presentation/common/error/app_message_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import '../../application/usecases/event_share_service.dart';

/// TR0100: イベント内の 1 つの支払い（取引）を入力・編集する画面
///
/// スクショ「岡山ホテル」画面のイメージに合わせて、以下を入力できる:
/// - イベント名（取引名）: テキスト入力
/// - 支払い情報: 合計金額（えん）
/// - 支払った人: イベント参加メンバーから 1 人選択
/// - 内訳設定ゾーン:
///    - チェックボックス: この人を割り勘対象に含めるか
///    - 名前
///    - 個別金額フィールド: 1 人あたりの負担額を編集可能
///
/// 合計金額を変更したときや割り勘対象の人を変更したときに、
/// application/usecases/event_share_service.dart の EventShareService を使って
/// 均等割り額を自動で振り分ける簡易ロジックを入れている。
class Tr0100TransactionScreen extends ConsumerStatefulWidget {
  const Tr0100TransactionScreen({
    super.key,
    required this.eventId,
    this.transactionId,
  });

  final String eventId;
  final String? transactionId;

  @override
  ConsumerState<Tr0100TransactionScreen> createState() =>
      _Tr0100TransactionScreenState();
}

class _Tr0100TransactionScreenState
    extends ConsumerState<Tr0100TransactionScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  final _eventShareService = EventShareService();
  bool _initialized = false;
  bool _missingEventId = false;

  /// イベント参加者（本来は eventId から取得）
  late final List<_EventMember> _members;

  /// 誰が払ったか
  String? _payerUserId;

  String? _eventTitle;
  String? _eventId;
  Transaction? _editingTransaction;

  /// 内訳設定ゾーンを表示するかどうか
  bool _showBreakdown = false;
  bool _payerExpanded = false;

  /// 各メンバーの割り勘設定（チェック状態＋個別金額）
  late List<_MemberShareState> _memberShares;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initFromParams(widget.eventId, widget.transactionId);
    _initialized = true;
  }

  void _initFromParams(String? eventIdParam, String? transactionId) {
    _eventId = eventIdParam;
    if (_eventId == null || _eventId!.isEmpty) {
      _missingEventId = true;
      _members = [];
      _titleController = TextEditingController(text: '');
      _amountController = TextEditingController(text: '');
      _memberShares = [];
      return;
    }

    _editingTransaction = _findTransaction(transactionId);
    final meta = ref.read(eventMetaProvider(_eventId!));
    if (meta == null) {
      _missingEventId = true;
      _members = [];
      _titleController = TextEditingController(text: '');
      _amountController = TextEditingController(text: '');
      _memberShares = [];
      return;
    }

    _eventTitle = meta.title;
    _members = _resolveMembers(_eventId, _editingTransaction);
    _titleController = TextEditingController(
      text: _editingTransaction?.title ?? '',
    );
    _amountController = TextEditingController(
      text: _editingTransaction == null
          ? ''
          : _editingTransaction!.totalAmount.toString(),
    );

    _memberShares = _members.map((m) {
      final shares = _editingTransaction?.shares;
      final amount = shares == null ? null : shares[m.id];
      final included = _editingTransaction == null ? true : amount != null;
      final amountText = amount?.toString() ?? '';
      return _MemberShareState(
        memberId: m.id,
        name: m.displayName,
        included: included,
        controller: TextEditingController(text: amountText),
      );
    }).toList();

    if (_members.isNotEmpty) {
      _payerUserId = _editingTransaction?.paidBy ?? _members.first.id;
    }
  }

  String _generateTxId(String? eventId) {
    final e = (eventId == null || eventId.isEmpty)
        ? 'personal'
        : eventId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    final ts = DateTime.now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final rnd = Random().nextInt(1000).toString().padLeft(3, '0');
    return 'tx_${e}_$ts$rnd';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final s in _memberShares) {
      s.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_missingEventId) {
      return _EventErrorView(
        title: 'おしはらいメモ',
        message: 'eventIdが未指定です。',
        onBack: () => context.go('/ev0100'),
      );
    }

    final theme = Theme.of(context);

    final localTheme = theme.copyWith(
      checkboxTheme: AppControlThemes.checkbox,
      radioTheme: AppControlThemes.radio,
      unselectedWidgetColor: AppColors.selectionBorder,
    );

    return Theme(
      data: localTheme,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          title: Text(
            _eventTitle == null ? 'おしはらいメモ' : _eventTitle!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: AppTextSizes.title,
              fontWeight: AppFontWeights.appBarTitle,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(CupertinoIcons.trash),
              tooltip: 'このきろくをけす',
              onPressed: _onDeleteRecord,
            ),
          ],
        ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SoftInputCard(
                  child: Row(
                    children: [
                      const _IconBadge(icon: Icons.edit_note),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: AppTextSizes.section,
                            fontWeight: AppFontWeights.listTitle,
                          ),
                          decoration: InputDecoration(
                            hintText: 'イベントをいれてね',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: AppTextSizes.body,
                              color: theme.hintColor,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _SoftInputCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: AppTextSizes.section,
                            fontWeight: AppFontWeights.listTitle,
                          ),
                          decoration: InputDecoration(
                            hintText: 'きんがく',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: AppTextSizes.body,
                              color: theme.hintColor,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) => _recalcShares(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.amountUnit,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: AppTextSizes.body,
                          fontWeight: AppFontWeights.label,
                          color: AppColors.iconDefault,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _AccordionCard(
                  title: 'だれがはらった？',
                  summary: _payerUserId == null
                      ? 'えらんでね'
                      : _members
                            .firstWhere((m) => m.id == _payerUserId)
                            .displayName,
                  expanded: _payerExpanded,
                  onToggle: (value) {
                    setState(() => _payerExpanded = value);
                  },
                  child: Column(
                    children: _members.map((m) {
                      return RadioListTile<String>(
                        value: m.id,
                        groupValue: _payerUserId,
                        onChanged: (value) {
                          setState(() => _payerUserId = value);
                        },
                        title: Text(
                          m.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.listTitle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _AccordionCard(
                  title: 'わりかんのせってい',
                  summary: _memberShares.every((s) => s.included)
                      ? 'ぜんいん'
                      : 'いちぶ',
                  expanded: _showBreakdown,
                  onToggle: (value) {
                    setState(() => _showBreakdown = value);
                  },
                  child: Column(
                    children: _memberShares.map((s) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: s.included,
                              onChanged: (v) {
                                setState(() {
                                  s.included = v ?? false;
                                  if (!s.included) {
                                    s.controller.text = '';
                                  }
                                  _recalcShares();
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: AppTextSizes.body,
                                  fontWeight: AppFontWeights.listTitle,
                                ),
                              ),
                            ),
                            Container(
                              width: 100,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.card,
                                ),
                              ),
                              child: TextField(
                                controller: s.controller,
                                enabled: s.included,
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.number,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: AppTextSizes.body,
                                  fontWeight: AppFontWeights.listTitle,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: AppTextSizes.body,
                                    color: theme.hintColor,
                                  ),
                                  isDense: true,
                                  suffixText: AppStrings.amountUnit,
                                  suffixStyle: theme.textTheme.bodySmall
                                      ?.copyWith(
                                        fontSize: AppTextSizes.body,
                                        fontWeight: AppFontWeights.listTitle,
                                        color: theme.hintColor,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onTapSave,
              style: AppButtonStyles.primaryPill,
              child: Text(
                'ほぞん',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: AppTextSizes.body,
                  fontWeight: AppFontWeights.label,
                  color: AppColors.primaryActionText,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  /// 合計金額や割り勘対象が変わったときに均等割りを再計算し、
  /// 各メンバーの TextField に反映する。
  void _recalcShares() {
    final total = int.tryParse(_amountController.text) ?? 0;
    final includedShares = _memberShares.where((s) => s.included).toList();

    if (includedShares.isEmpty) {
      return;
    }

    if (total <= 0) {
      // 金額がない場合は金額入力だけクリアする
      setState(() {
        for (final s in includedShares) {
          s.controller.text = '';
        }
      });
      return;
    }

    final result = _eventShareService.calcEqualShares(
      totalAmount: total,
      beneficiaryUserIds: includedShares.map((s) => s.memberId).toList(),
    );

    setState(() {
      for (final s in includedShares) {
        final value = result[s.memberId];
        if (value != null) {
          s.controller.text = value.toString();
        }
      }
    });
  }

  Transaction? _findTransaction(String? transactionId) {
    if (transactionId == null || transactionId.isEmpty) {
      return null;
    }
    if (_eventId == null || _eventId!.isEmpty) return null;
    final txs = ref.read(transactionsByEventProvider(_eventId!));
    for (final tx in txs) {
      if (tx.id == transactionId && tx.deletedAt == null) return tx;
    }
    return null;
  }

  List<_EventMember> _resolveMembers(
    String? eventId,
    Transaction? transaction,
  ) {
    final memberIds = <String>[];
    final seen = <String>{};
    void addIfMissing(String id) {
      if (seen.add(id)) {
        memberIds.add(id);
      }
    }

    if (eventId != null && eventId.isNotEmpty) {
      final meta = ref.read(eventMetaProvider(eventId));
      if (meta != null) {
        for (final id in meta.participantIds) {
          addIfMissing(id);
        }
      }
    }

    if (transaction != null) {
      if (transaction.type == TxType.expense) {
        final paidBy = transaction.paidBy;
        if (paidBy != null) {
          addIfMissing(paidBy);
        }
        final shares = transaction.shares;
        if (shares != null) {
          for (final id in shares.keys) {
            addIfMissing(id);
          }
        }
      } else {
        if (transaction.fromUserId != null) {
          addIfMissing(transaction.fromUserId!);
        }
        if (transaction.toUserId != null) {
          addIfMissing(transaction.toUserId!);
        }
      }
    }

    return memberIds
        .map(
          (id) => _EventMember(
            id: id,
            displayName: ref.watch(userDisplayNameProvider(id)),
          ),
        )
        .toList();
  }

  Future<void> _onTapSave() async {
    final total = int.tryParse(_amountController.text) ?? 0;

    if (_eventId == null || _eventId!.isEmpty) {
      _showError(this.context, 'eventIdが未指定です。');
      return;
    }
    if (_payerUserId == null || _payerUserId!.isEmpty) {
      _showError(this.context, 'はらったひとをえらんでね。');
      return;
    }
    if (total <= 0) {
      _showError(this.context, 'ごうけいきんがくをいれてね。');
      return;
    }
    final included = _memberShares.where((s) => s.included).toList();
    if (included.isEmpty) {
      _showError(this.context, 'すくなくともひとりはわりかんメンバーにしてね。');
      return;
    }

    // Map UI -> Transaction and save via repository
    final id = _editingTransaction?.id ?? _generateTxId(_eventId);
    final createdAt = _editingTransaction?.createdAt ?? DateTime.now();

    // Build shares: 割り勘対象のみ集計し、差分がある場合は不足/過剰額を表示して保存しない
    final shares = <String, int>{};
    int sumShares = 0;
    for (final s in included) {
      final text = s.controller.text.trim();
      final parsed = text.isEmpty ? 0 : int.tryParse(text);
      if (parsed == null || parsed < 0) {
        _showError(this.context, 'わりかんの きんがく は 0 いじょう の すうじで いれてね。');
        return;
      }
      shares[s.memberId] = parsed;
      sumShares += parsed;
    }
    if (sumShares != total) {
      final diff = total - sumShares;
      final diffAmount = diff.abs().toString();
      final message = diff > 0
          ? '$diffAmount${AppStrings.amountUnit} たりないよ。'
          : '$diffAmount${AppStrings.amountUnit} おおすぎるよ。';
      _showError(
        this.context,
        message,
      );
      return;
    }

    final eventId = _eventId!;
    final participantIds = <String>{...shares.keys};
    if (_payerUserId != null) {
      participantIds.add(_payerUserId!);
    }
    final tx = Transaction(
      id: id,
      eventId: eventId,
      type: TxType.expense,
      title: _titleController.text.trim().isEmpty
          ? 'メモ'
          : _titleController.text.trim(),
      date: _editingTransaction?.date ?? DateTime.now(),
      currency: 'JPY',
      totalAmount: total,
      participantIds: participantIds.toList(growable: false),
      paidBy: _payerUserId ?? included.first.memberId,
      shares: Map<String, int>.unmodifiable(shares),
      fromUserId: null,
      toUserId: null,
      repaymentAmount: null,
      createdBy:
          _editingTransaction?.createdBy ??
          (_payerUserId ?? included.first.memberId),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      deletedAt: _editingTransaction?.deletedAt,
    );

    // Persist to state
    try {
      await ref.read(transactionRepositoryProvider).upsert(tx);
    } catch (e, st) {
      final err = toAppError(e, st);
      if (!mounted) return;
      await showAppErrorDialog(context: this.context, error: err);
      return;
    }

    if (!mounted) return;
    this.context.pop();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _onDeleteRecord() async {
    await showAppMessageDialog(
      context: context,
      messageId: AppMessageId.tr0100_001,
      closeOnDestructiveSuccess: false,
      onDestructive: () async {
        if (_editingTransaction != null) {
          await ref
              .read(transactionRepositoryProvider)
              .delete(_editingTransaction!.id);
        }
        if (!mounted) return;
        Navigator.of(this.context, rootNavigator: true).pop();
        this.context.pop();
      },
    );
  }
}

class _SoftInputCard extends StatelessWidget {
  const _SoftInputCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.subtle,
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.iconDefault, size: 20),
    );
  }
}

class _EventErrorView extends StatelessWidget {
  const _EventErrorView({
    required this.title,
    required this.message,
    required this.onBack,
  });

  final String title;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        onBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: AppTextSizes.title,
                  fontWeight: AppFontWeights.appBarTitle,
                ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                    ),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: onBack, child: const Text('もどる')),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String? summary;
  final bool expanded;
  final ValueChanged<bool> onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: expanded
              ? AppColors.secondaryActionBorder
              : AppColors.listBorder,
          style: expanded ? BorderStyle.solid : BorderStyle.solid,
        ),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.card),
            onTap: () => onToggle(!expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.sectionTitle,
                          ),
                        ),
                        if (summary != null)
                          Text(
                            summary!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: AppTextSizes.small,
                              fontWeight: AppFontWeights.listSubtitle,
                              color: theme.hintColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// 画面内だけで使うメンバー／内訳状態
/// ---------------------------
class _EventMember {
  final String id;
  final String displayName;

  const _EventMember({required this.id, required this.displayName});
}

class _MemberShareState {
  _MemberShareState({
    required this.memberId,
    required this.name,
    required this.included,
    required this.controller,
  });

  final String memberId;
  final String name;
  bool included;
  final TextEditingController controller;
}
