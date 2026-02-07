import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/chat_message_providers.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/domain/models/chat_message_model.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';
import 'package:shakuyousho_app/presentation/common/strings.dart';

/// FR0200: 友達との取引詳細（friends_page.dart FriendDetailPage 準拠）
/// - チャット風タイムライン
/// - iMessage風バブル
/// - メッセージ入力欄
/// - 「みかえし」フローティングチップ
class Fr0200ThreadDetailScreen extends ConsumerStatefulWidget {
  const Fr0200ThreadDetailScreen({super.key, required this.friendId});

  final String friendId;

  @override
  ConsumerState<Fr0200ThreadDetailScreen> createState() =>
      _Fr0200ThreadDetailScreenState();
}

class _Fr0200ThreadDetailScreenState
    extends ConsumerState<Fr0200ThreadDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool force = false, bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      final distance = pos.maxScrollExtent - pos.pixels;
      if (!force && distance > 180) return;
      if (jump) {
        _scrollController.jumpTo(pos.maxScrollExtent);
        return;
      }
      _scrollController.animateTo(
        pos.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _scheduleInitialScroll() {
    if (_didInitialScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollController.hasClients) {
        _scheduleInitialScroll();
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _didInitialScroll = true;
    });
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    ref
        .read(chatMessageActionsProvider.notifier)
        .sendMessage(
          threadId: widget.friendId,
          senderId: ref.read(currentUserIdProvider),
          text: text,
        );
    _messageController.clear();
    _scrollToBottom(force: true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.friendId.isEmpty) {
      return _ErrorView(
        message: 'friendId が未指定です。',
        onBack: () => context.go('/fr0100'),
      );
    }

    final displayName = ref.watch(userDisplayNameProvider(widget.friendId));
    final loansAsync = ref.watch(loansByCounterpartyProvider(widget.friendId));

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(displayName, style: const TextStyle(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('エラー: $e')),
          data: (loans) {
            final messages = ref.watch(
              messagesByThreadProvider(widget.friendId),
            );
            return _buildBody(context, loans, messages);
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Loan> loans,
    List<ChatMessage> messages,
  ) {
    // 初回表示は必ず最下部へ
    _scheduleInitialScroll();

    return Stack(
      children: [
        Column(
          children: [
            _buildLoanSummaryHeader(loans),
            // タイムライン
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  child: _buildTimeline(loans, messages),
                ),
              ),
            ),
            // 入力欄
            _buildInputBar(context),
          ],
        ),
        // みかえしチップ
        _buildUnpaidChip(loans),
      ],
    );
  }

  Widget _buildLoanSummaryHeader(List<Loan> loans) {
    var toPay = 0; // これから かえす（自分が借りた）
    var toReceive = 0; // これから かえってくる（自分が貸した）
    for (final loan in loans) {
      if (loan.remainingYen == 0) continue;
      if (loan.direction == LoanDirection.borrowed) {
        toPay += loan.remainingYen;
      } else {
        toReceive += loan.remainingYen;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'いまの じょうたい',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            'これから かえす：${AppStrings.amountWithUnit(_fmtYen(toPay))}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'これから かえってくる：${AppStrings.amountWithUnit(_fmtYen(toReceive))}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<Loan> loans, List<ChatMessage> messages) {
    // タイムライン項目（借用書 + メッセージ）を1列に
    final items = <({DateTime t, bool isLoan, Loan? loan, ChatMessage? msg})>[];

    for (final l in loans) {
      items.add((t: l.createdAt, isLoan: true, loan: l, msg: null));
    }
    for (final m in messages) {
      items.add((t: m.createdAt, isLoan: false, loan: null, msg: m));
    }

    // 古い→新しい
    items.sort((a, b) => a.t.compareTo(b.t));

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Text(
            'まだ やりとり が ないよ',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final children = <Widget>[];
    String? lastDate;

    for (final it in items) {
      final dateLabel = _fmtDate(it.t);
      if (lastDate != dateLabel) {
        lastDate = dateLabel;
        children.add(_DateChip(label: dateLabel));
      }

      if (it.isLoan && it.loan != null) {
        final loan = it.loan!;
        final myId = ref.read(currentUserIdProvider);
        final isMe = loan.createdBy.isNotEmpty
            ? loan.createdBy == myId
            : loan.direction == LoanDirection.lent;
        children.add(
          _TxBubble(
            isMe: isMe,
            amount: '¥${_fmtYen(loan.amountYen)}',
            label: loan.direction == LoanDirection.lent ? 'かした' : 'かりた',
            memo: loan.purpose,
            date: _fmtDate(loan.createdAt),
            due: _fmtDate(loan.dueDate),
            isDone: loan.isRepaid,
            status: loan.status,
            remainingYen: loan.remainingYen,
            repaidYen: loan.repaidYen,
            onTap: () => _showLoanSheet(loan),
          ),
        );
      } else if (it.msg != null) {
        final msg = it.msg!;
        final myId = ref.read(currentUserIdProvider);
        children.add(_ChatBubble(isMe: msg.senderId == myId, text: msg.text));
      }
    }

    children.add(const SizedBox(height: 8));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: scaffoldBg,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // 借用書追加ボタン
          IconButton(
            icon: const Icon(CupertinoIcons.doc_text, color: Color(0xFF34C759)),
            onPressed: () =>
                context.push('/lb0200?friendId=${widget.friendId}'),
          ),
          // テキスト入力
          Expanded(
            child: CupertinoTextField(
              controller: _messageController,
              placeholder: 'メッセージ',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 6),
          // 送信ボタン
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Color(0xFF34C759),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpaidChip(List<Loan> loans) {
    // 自分がかりた未返済
    final unpaid = loans.where(
      (l) =>
          l.direction == LoanDirection.borrowed &&
          l.status != LoanStatus.rejected &&
          !l.isRepaid,
    );

    var count = 0;
    var sum = 0;
    for (final l in unpaid) {
      count++;
      sum += l.remainingYen;
    }

    if (count == 0) return const SizedBox.shrink();

    return Positioned(
      right: 14,
      bottom: 80,
      child: GestureDetector(
        onTap: () => _showUnpaidListSheet(loans),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Text(
                'みかえし $count けん ¥${_fmtYen(sum)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoanSheet(Loan loan) {
    final isBorrowed = loan.direction == LoanDirection.borrowed;
    final canRepay =
        isBorrowed && !loan.isRepaid && loan.status != LoanStatus.rejected;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ヘッダー
                  Row(
                    children: [
                      Text(
                        loan.direction == LoanDirection.lent ? 'かした' : 'かりた',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusBadge(status: loan.status),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 金額
                  Text(
                    '¥${_fmtYen(loan.amountYen)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loan.purpose,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'めやすのひ：${_fmtDate(loan.dueDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  ),
                  // 返済状況
                  if (loan.repayments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'へんさい：¥${_fmtYen(loan.repaidYen)} / ¥${_fmtYen(loan.amountYen)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // アクション
                  if (canRepay)
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: const Color(0xFF34C759),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRepayDialog(loan);
                        },
                        child: const Text(
                          'かえす',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  // 承認/拒否（かした側のpendingのみ）
                  if (loan.direction == LoanDirection.lent &&
                      loan.status == LoanStatus.pending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref
                                  .read(loanActionsProvider.notifier)
                                  .approveLoan(loan.id);
                            },
                            child: const Text(
                              'しょうにん',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref
                                  .read(loanActionsProvider.notifier)
                                  .rejectLoan(loan.id);
                            },
                            child: const Text(
                              'きょひ',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // 詳細へ
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/lb0200/${loan.id}');
                      },
                      child: const Text(
                        'しょうさい を みる',
                        style: TextStyle(color: Color(0xFF374151)),
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

  Future<void> _showRepayDialog(Loan loan) async {
    final controller = TextEditingController(
      text: loan.remainingYen.toString(),
    );

    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('かえす'),
          content: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('のこり ¥${_fmtYen(loan.remainingYen)}'),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  placeholder: 'きんがく',
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(AppStrings.amountUnit),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('やめる'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final amount = int.tryParse(controller.text.trim());
                if (amount == null || amount <= 0) return;
                ref
                    .read(loanActionsProvider.notifier)
                    .addRepayment(loan.id, amount);
                Navigator.pop(ctx);
                _scrollToBottom(force: true);
              },
              child: const Text('かえす'),
            ),
          ],
        );
      },
    );
  }

  void _showUnpaidListSheet(List<Loan> loans) {
    final unpaid =
        loans
            .where(
              (l) =>
                  l.direction == LoanDirection.borrowed &&
                  l.status != LoanStatus.rejected &&
                  !l.isRepaid,
            )
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (unpaid.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'みかえし いちらん',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...unpaid.map(
                    (loan) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showLoanSheet(loan);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loan.purpose,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'めやす：${_fmtDate(loan.dueDate)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '¥${_fmtYen(loan.remainingYen)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
}

// ────────────────────────────────────────────────────────────────
// サブウィジェット
// ────────────────────────────────────────────────────────────────

/// 日付チップ
class _DateChip extends StatelessWidget {
  final String label;
  const _DateChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ),
      ),
    );
  }
}

/// チャットバブル
class _ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  const _ChatBubble({required this.isMe, required this.text});

  @override
  Widget build(BuildContext context) {
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMe
        ? const Color(0xFF34C759).withValues(alpha: 0.18)
        : const Color(0xFFF3F4F6);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
    );

    return Align(
      alignment: align,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: isMe ? 40 : 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFF4B5563).withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        ),
      ),
    );
  }
}

/// 借用書バブル（iMessage風）
class _TxBubble extends StatelessWidget {
  final bool isMe;
  final String amount;
  final String label;
  final String memo;
  final String date;
  final String due;
  final bool isDone;
  final LoanStatus status;
  final int remainingYen;
  final int repaidYen;
  final VoidCallback? onTap;

  const _TxBubble({
    required this.isMe,
    required this.amount,
    required this.label,
    required this.memo,
    required this.date,
    required this.due,
    this.isDone = false,
    this.status = LoanStatus.approved,
    this.remainingYen = 0,
    this.repaidYen = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleColor = isMe
        ? const Color(0xFF34C759).withOpacity(0.18)
        : const Color(0xFFF3F4F6);

    final borderColor = isMe
        ? const Color(0xFF34C759).withOpacity(0.6)
        : const Color(0xFF4B5563).withOpacity(0.15);

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
    );

    return Align(
      alignment: align,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: isMe ? 40 : 8),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: status),
                  if (isDone) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'かんさい',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // 金額
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              // メモ
              Text(
                memo,
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              // 返済状況
              if (repaidYen > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'へんさい：¥${_fmtYen(repaidYen)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 6),
              // 日付
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'めやす：$due',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ステータスバッジ
class _StatusBadge extends StatelessWidget {
  final LoanStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      LoanStatus.pending => (
        'しんせいちゅう',
        const Color(0xFFFEF3C7),
        const Color(0xFFD97706),
      ),
      LoanStatus.approved => (
        'しょうにんずみ',
        const Color(0xFFDCFCE7),
        const Color(0xFF059669),
      ),
      LoanStatus.rejected => (
        'きょひ',
        const Color(0xFFFEE2E2),
        const Color(0xFFDC2626),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

/// エラー画面
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBack;
  const _ErrorView({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          title: const Text('FR0200'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 12),
              CupertinoButton(onPressed: onBack, child: const Text('もどる')),
            ],
          ),
        ),
      ),
    );
  }
}

// ユーティリティ
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
