import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/chat_message_providers.dart';
import 'package:shakuyousho_app/application/providers/loan_providers.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import 'package:shakuyousho_app/core/extensions/date_time_extension.dart';
import 'package:shakuyousho_app/core/extensions/num_extension.dart';
import 'package:shakuyousho_app/domain/models/chat_message_model.dart';
import 'package:shakuyousho_app/domain/models/loan_model.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/strings.dart';
import 'package:shakuyousho_app/presentation/common/app_paper_background.dart';
import 'package:shakuyousho_app/presentation/common/app_loading_screen.dart';
import 'package:shakuyousho_app/presentation/common/error/app_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import 'package:shakuyousho_app/presentation/common/error/app_message_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';

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
  bool _didShowReadError = false;

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
      if (!pos.hasContentDimensions) return;
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
      if (!_scrollController.hasClients ||
          !_scrollController.position.hasContentDimensions) {
        _scheduleInitialScroll();
        return;
      }
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _didInitialScroll = true;
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try {
      await ref
          .read(chatMessageActionsProvider.notifier)
          .sendMessage(
            threadId: widget.friendId,
            senderId: ref.read(currentUserIdProvider),
            text: text,
          );
    } catch (e, st) {
      final err = toAppError(e, st);
      if (!mounted) return;
      await showAppErrorDialog(context: context, error: err);
      return;
    }
    if (!mounted) return;
    _messageController.clear();
    _scrollToBottom(force: true);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: Text(
          displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: AppTextSizes.title,
                fontWeight: AppFontWeights.appBarTitle,
              ),
        ),
        centerTitle: true,
        backgroundColor: AppPaperBackground.baseColor,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: loansAsync.when(
          loading: () => const AppLoadingScreen(),
          error: (e, st) {
            _handleReadError(e, st);
            return Center(
              child: Text(
                AppMessages.dialog(AppMessageId.s004).message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                      color: Theme.of(context).hintColor,
                    ),
              ),
            );
          },
          data: (loans) {
            List<ChatMessage> messages;
            try {
              messages = ref.watch(
                messagesByThreadProvider(widget.friendId),
              );
            } catch (e, st) {
              _handleReadError(e, st);
              return Center(
                child: Text(
                  AppMessages.dialog(AppMessageId.s004).message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: AppTextSizes.body,
                        color: Theme.of(context).hintColor,
                      ),
                ),
              );
            }
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
        // フローティングボタン（みうけとり + みへんさい）
        _buildFloatingButtons(loans),
      ],
    );
  }

  Widget _buildLoanSummaryHeader(List<Loan> loans) {
    var toPay = 0; // これから かえす（自分が借りた）
    var toReceive = 0; // これから かえってくる（自分が貸した）
    for (final loan in loans) {
      if (loan.remainingYen == 0) continue;
      if (loan.lenderUserId == ref.read(currentUserIdProvider)) {
        toReceive += loan.remainingYen;
      } else {
        toPay += loan.remainingYen;
      }
    }

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      // カード装飾をやめてフラットにする（背景は親の scaffold に従う）
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'これから かえす',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppTextSizes.body,
                  fontWeight: AppFontWeights.listSubtitle,
                ),
              ),
              Text(
                toPay.toYenSymbol(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppTextSizes.section,
                  fontWeight: AppFontWeights.listTitle,
                  color: AppColors.borrowAmount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'これから かえってくる',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppTextSizes.body,
                  fontWeight: AppFontWeights.listSubtitle,
                ),
              ),
              Text(
                toReceive.toYenSymbol(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppTextSizes.section,
                  fontWeight: AppFontWeights.listTitle,
                  color: AppColors.lendAmount,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 下に細い境界線を引く
          Container(
            height: 1,
            color: AppColors.listBorder,
            margin: const EdgeInsets.only(top: 6),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: AppTextSizes.body,
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
      );
    }

    final children = <Widget>[];
    String? lastDate;

    for (final it in items) {
      final dateLabel = it.t.toYmdSlash();
      if (lastDate != dateLabel) {
        lastDate = dateLabel;
        children.add(_DateChip(label: dateLabel));
      }

      if (it.isLoan && it.loan != null) {
        final loan = it.loan!;
        final myId = ref.read(currentUserIdProvider);
        final isMe = loan.lenderUserId == myId;
        final friendName = ref.read(userDisplayNameProvider(widget.friendId));
        final label = isMe ? '$friendName さんに かした' : '$friendName さんから かりた';
        children.add(
          _TxBubble(
            isMe: isMe,
            label: label,
            amount: loan.amountYen.toYenSymbol(),
            memo: loan.purpose,
            note: loan.note,
            due: loan.dueDate.toYmdSlash(),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: scaffoldBg,
        border: const Border(top: BorderSide(color: AppColors.listBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 借用書追加ボタン
          IconButton(
            icon: const Icon(CupertinoIcons.doc_text),
            color: AppColors.iconDefault,
            onPressed: () =>
                context.push('/lb0200?friendId=${widget.friendId}'),
          ),
          const SizedBox(width: 10),
          // テキスト入力
          Expanded(
            child: CupertinoTextField(
              controller: _messageController,
              placeholder: 'めっせーじ を 入力',
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.addButtonBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.listBorder),
              ),
              suffix: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.sentiment_satisfied_alt_outlined,
                  size: 20,
                  color: AppColors.iconDefault,
                ),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 10),
          // 送信ボタン（おくる）
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              margin: const EdgeInsets.only(bottom: 1),
              decoration: BoxDecoration(
                color: AppColors.addButtonBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.listBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                'おくる',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.label,
                      color: Colors.black,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButtons(List<Loan> loans) {
    final myId = ref.read(currentUserIdProvider);

    // みうけとり: 自分が貸した未返済
    var recvCount = 0;
    var recvSum = 0;
    for (final l in loans) {
      if (l.lenderUserId == myId && !l.isRepaid) {
        recvCount++;
        recvSum += l.remainingYen;
      }
    }

    // みへんさい: 自分が借りた未返済
    var payCount = 0;
    var paySum = 0;
    for (final l in loans) {
      if (l.lenderUserId != myId && !l.isRepaid) {
        payCount++;
        paySum += l.remainingYen;
      }
    }

    if (recvCount == 0 && payCount == 0) return const SizedBox.shrink();

    return Positioned(
      right: 14,
      bottom: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // みうけとり（紫）
          if (recvCount > 0)
            GestureDetector(
              onTap: () => _showReceivableListSheet(loans),
              child: Container(
                width: 110,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.listBorder),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'みうけとり',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: AppTextSizes.tiny,
                            fontWeight: AppFontWeights.label,
                            color: AppColors.lendAmount,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$recvCount 件',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: AppTextSizes.tiny,
                            color: AppColors.iconDefault,
                          ),
                    ),
                    Text(
                      recvSum.toYenSymbol(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.listTitle,
                            color: AppColors.lendAmount,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          if (recvCount > 0 && payCount > 0) const SizedBox(height: 8),
          // みへんさい（黒）
          if (payCount > 0)
            GestureDetector(
              onTap: () => _showUnpaidListSheet(loans),
              child: Container(
                width: 110,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.listBorder),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'みへんさい',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: AppTextSizes.tiny,
                            fontWeight: AppFontWeights.label,
                            color: AppColors.borrowAmount,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paySum.toYenSymbol(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.listTitle,
                            color: AppColors.borrowAmount,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLoanSheet(Loan loan) {
    final myId = ref.read(currentUserIdProvider);
    final isMe = loan.lenderUserId == myId;
    final canRepay = !isMe && !loan.isRepaid;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: loan.isRepaid
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          loan.remainingYen == 0 ? 'しはらいかんりょう' : 'みへんさい',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: AppTextSizes.small,
                            fontWeight: AppFontWeights.label,
                            color: loan.remainingYen == 0
                                ? const Color(0xFF059669)
                                : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.iconDefault,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 金額
                  Text(
                    loan.amountYen.toYenSymbol(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: AppTextSizes.amountXL,
                      fontWeight: AppFontWeights.listTitle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loan.purpose,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                      color: AppColors.iconDefault,
                    ),
                  ),
                  // 備考
                  if (loan.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'びこう：${loan.note}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: AppTextSizes.small,
                        color: AppColors.iconDefault,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'きげん：${loan.dueDate.toYmdSlash()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: AppTextSizes.small,
                      color: theme.hintColor,
                    ),
                  ),
                  // 返済状況
                  const SizedBox(height: 12),
                  Text(
                    'のこり：${loan.remainingYen.toYenSymbol()}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.body,
                    ),
                  ),
                  if (loan.repayments.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'へんさい：${loan.repaidYen.toYenSymbol()} / ${loan.amountYen.toYenSymbol()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: AppTextSizes.small,
                      ),
                    ),
                  ],
                  if (loan.remainingYen == 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      'しはらいかんりょう',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: AppTextSizes.small,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // アクション：相手からの借用書 → かえす
                  if (canRepay)
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: AppColors.primaryActionFill,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRepayDialog(loan);
                        },
                        child: Text(
                          'かえす',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.label,
                            color: AppColors.primaryActionText,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  // 詳細へ
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.addButtonBackground,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/lb0200/${loan.id}');
                      },
                      child: Text(
                        'しょうさい を みる',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: AppTextSizes.body,
                          fontWeight: AppFontWeights.label,
                          color: AppColors.iconDefault,
                        ),
                      ),
                    ),
                  ),
                  // 削除（自分が発行した借用書のみ）
                  if (isMe) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDelete(loan);
                        },
                        child: Text(
                          'さくじょ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: AppTextSizes.body,
                            fontWeight: AppFontWeights.label,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(Loan loan) async {
    await showAppMessageDialog(
      context: context,
      messageId: AppMessageId.fr0200_001,
      onDestructive: () async {
        await ref.read(loanActionsProvider.notifier).deleteLoan(loan.id);
      },
    );
  }

  Future<void> _showRepayDialog(Loan loan) async {
    final controller = TextEditingController(
      text: loan.remainingYen.toString(),
    );

    await showAppContentDialog(
      context: context,
      title: 'かえす',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('のこり ${loan.remainingYen.toYenSymbol()}'),
          const SizedBox(height: 8),
          CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            placeholder: 'きんがく',
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(AppStrings.amountUnit),
            ),
          ),
        ],
      ),
      actions: [
        const AppDialogAction(
          label: 'やめる',
          style: AppDialogActionStyle.secondary,
        ),
        AppDialogAction(
          label: 'かえす',
          style: AppDialogActionStyle.primary,
          closeOnSuccess: false,
          onPressedAsync: () async {
            final amount = int.tryParse(controller.text.trim());
            if (amount == null || amount <= 0) {
              await showAppDialog(
                context: context,
                title: 'エラー',
                message: 'きんがく を いれてね',
              );
              return;
            }
            if (amount > loan.remainingYen) {
              await showAppDialog(
                context: context,
                title: 'エラー',
                message: 'のこり より おおきい きんがく は いれられないよ',
              );
              return;
            }
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pop();
            try {
              await ref
                  .read(loanActionsProvider.notifier)
                  .addRepayment(loan.id, amount);
            } catch (e, st) {
              final err = toAppError(e, st);
              if (!mounted) return;
              await showAppErrorDialog(context: context, error: err);
              return;
            }
            if (!mounted) return;
            _scrollToBottom(force: true);
          },
        ),
      ],
    );
  }

  void _showReceivableListSheet(List<Loan> loans) {
    final myId = ref.read(currentUserIdProvider);
    final receivable =
        loans.where((l) => l.lenderUserId == myId && !l.isRepaid).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (receivable.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
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
                      Text(
                        'みうけとり いちらん',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: AppTextSizes.section,
                          fontWeight: AppFontWeights.sectionTitle,
                          color: AppColors.lendAmount,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.iconDefault,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...receivable.map(
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: AppTextSizes.body,
                                    ),
                                  ),
                                  Text(
                                    'きげん：${loan.dueDate.toYmdSlash()}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: AppTextSizes.small,
                                      color: AppColors.iconDefault,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              loan.remainingYen.toYenSymbol(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: AppTextSizes.section,
                                fontWeight: AppFontWeights.listTitle,
                                color: AppColors.lendAmount,
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

  void _showUnpaidListSheet(List<Loan> loans) {
    final myId = ref.read(currentUserIdProvider);
    final unpaid =
        loans.where((l) => l.lenderUserId != myId && !l.isRepaid).toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    if (unpaid.isEmpty) return;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
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
                      Text(
                        'みかえし いちらん',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: AppTextSizes.section,
                          fontWeight: AppFontWeights.sectionTitle,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(
                          Icons.close,
                          color: AppColors.iconDefault,
                        ),
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: AppTextSizes.body,
                                    ),
                                  ),
                                  Text(
                                    'きげん：${loan.dueDate.toYmdSlash()}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: AppTextSizes.small,
                                      color: AppColors.iconDefault,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              loan.remainingYen.toYenSymbol(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: AppTextSizes.section,
                                fontWeight: AppFontWeights.listTitle,
                                color: AppColors.borrowAmount,
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
            color: AppColors.addButtonBackground,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: AppTextSizes.small,
                  color: AppColors.iconDefault,
                ),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: AppTextSizes.body,
                color: const Color(0xFF111827),
              ),
        ),
      ),
    );
  }
}

/// 借用書バブル（iMessage風）
class _TxBubble extends StatelessWidget {
  final bool isMe;
  final String label;
  final String amount;
  final String memo;
  final String note;
  final String due;
  final VoidCallback? onTap;

  const _TxBubble({
    required this.isMe,
    required this.label,
    required this.amount,
    required this.memo,
    this.note = '',
    required this.due,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;

    final bubbleColor = isMe
        ? const Color(0xFF34C759).withValues(alpha: 0.18)
        : const Color(0xFFF3F4F6);

    final borderColor = isMe
        ? const Color(0xFF34C759).withValues(alpha: 0.6)
        : const Color(0xFF4B5563).withValues(alpha: 0.15);

    final labelColor = const Color(0xFF6B7280);

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
          padding: const EdgeInsets.all(14),
          constraints: const BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ラベル（〇〇さんに かした / 〇〇さんから かりた）
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: AppTextSizes.small,
                      color: labelColor,
                    ),
              ),
              const SizedBox(height: 8),
              // 金額（中央揃え・大きく）
              Center(
                child: Text(
                  amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: AppTextSizes.amountLarge,
                        fontWeight: AppFontWeights.listTitle,
                        color: const Color(0xFF1F2937),
                      ),
                ),
              ),
              const SizedBox(height: 10),
              // セパレータ（借りた側のみ）
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: const Divider(height: 1, color: AppColors.listBorder),
                ),
              // ようと
              Text(
                'ようと : ${memo.isEmpty ? 'なし' : memo}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: AppTextSizes.small,
                      color: const Color(0xFF374151),
                    ),
              ),
              // 備考
              if (note.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'びこう : $note',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: AppTextSizes.small,
                        color: const Color(0xFF6B7280),
                      ),
                ),
              ],
              const SizedBox(height: 2),
              // 期限（赤色）
              Text(
                'きげん : $due',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: AppTextSizes.small,
                      fontWeight: AppFontWeights.listSubtitle,
                      color: const Color(0xFFDC2626),
                    ),
              ),
            ],
          ),
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
          title: Text(
            'ともだち',
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
              CupertinoButton(onPressed: onBack, child: const Text('もどる')),
            ],
          ),
        ),
      ),
    );
  }
}
