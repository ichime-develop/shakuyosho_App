import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/domain/models/event_models.dart';
import 'package:shakuyousho_app/presentation/common/common_bottom_nav_bar.dart';

/// EV0100: イベント一覧画面
/// - 旅行・飲み会などのイベント単位で、貸し借りを管理する入り口
/// - 各イベントの概要と「詳細(EV0200)」「精算(SV0100)」への導線を提供
class Ev0100EventListScreen extends ConsumerWidget {
  const Ev0100EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaries = ref.watch(eventSummariesProvider);
    final ongoing = summaries.where((e) => !e.isSettled).toList()
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
    final finished = summaries.where((e) => e.isSettled).toList()
      ..sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));

    return Scaffold(
      appBar: AppBar(title: const Text('EV0100 イベント一覧'), centerTitle: false),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 140),
              children: [
                _SectionHeader(
                  label: 'しんこうちゅう',
                  accentColor: theme.colorScheme.primary,
                ),
                const SizedBox(height: 8),
                if (ongoing.isEmpty)
                  _EmptyMessage(message: 'まだしんこうちゅうのイベントはないよ。', theme: theme)
                else
                  _EventList(
                    themes: theme,
                    events: ongoing,
                    onTap: (e) => _Controller.goDetail(context, e.id),
                    onAction: (e) => _Controller.goSettlement(context, e.id),
                  ),
                const SizedBox(height: 24),
                _SectionHeader(
                  label: 'せいさんずみ',
                  accentColor: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                if (finished.isEmpty)
                  _EmptyMessage(message: 'せいさんずみのイベントはまだありません。', theme: theme)
                else
                  _EventList(
                    themes: theme,
                    events: finished,
                    isFinished: true,
                    onTap: (e) => _Controller.goDetail(context, e.id),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            right: 24,
            child: _CreateFab(
              onPressed: () => _Controller.onCreateEvent(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(currentIndex: 2),
    );
  }
}

class _Controller {
  static void goDetail(BuildContext context, String eventId) {
    final uri = Uri(path: '/ev0200', queryParameters: {'eventId': eventId});
    context.push(uri.toString());
  }

  static void goSettlement(BuildContext context, String eventId) {
    final uri = Uri(path: '/sv0100', queryParameters: {'eventId': eventId});
    context.push(uri.toString());
  }

  static void onCreateEvent(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Ev0100EventEntrySheet(
          onTapCreateEvent: () async {
            Navigator.of(sheetCtx).pop();
            await Future.delayed(const Duration(milliseconds: 150));
            context.push('/gr0100');
          },
          onTapJoinEvent: () async {
            Navigator.of(sheetCtx).pop();
            await Future.delayed(const Duration(milliseconds: 150));
            context.push('/gr0200');
          },
          onTapCancel: () {
            Navigator.of(sheetCtx).pop();
          },
        );
      },
    );
  }
}

class Ev0100EventEntrySheet extends StatelessWidget {
  const Ev0100EventEntrySheet({
    Key? key,
    required this.onTapCreateEvent,
    required this.onTapJoinEvent,
    required this.onTapCancel,
  }) : super(key: key);

  final VoidCallback onTapCreateEvent;
  final VoidCallback onTapJoinEvent;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Text(
              'イベント',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onTapCreateEvent,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 28),
              label: const Text('イベントをつくる'),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onTapJoinEvent,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(color: theme.colorScheme.primary, width: 2),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.group_add_outlined, size: 28),
              label: const Text('イベントにさんかする'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onTapCancel,
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }
}

// mockEvents and mockTransactions are provided by lib/data/mock/event_mock.dart

String _fmtYen(int n) {
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final r = s.length - i;
    buf.write(s[i]);
    if (r > 1 && r % 3 == 1) buf.write(',');
  }
  return '¥${buf.toString()}';
}

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.accentColor,
    this.actionLabel,
    this.onTapAction,
  });

  final String label;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onTapAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onTapAction,
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.themes,
    required this.events,
    this.isFinished = false,
    required this.onTap,
    this.onAction,
  });

  final ThemeData themes;
  final List<EventSummary> events;
  final bool isFinished;
  final void Function(EventSummary) onTap;
  final void Function(EventSummary)? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        return Column(
          children: [
            _EventRow(
              summary: event,
              theme: themes,
              isFinished: isFinished,
              onTap: () => onTap(event),
              onAction: isFinished ? null : () => onAction?.call(event),
            ),
            if (index != events.length - 1)
              Divider(height: 1, thickness: 0.8, color: Colors.grey.shade200),
          ],
        );
      }),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.summary,
    required this.theme,
    required this.onTap,
    this.onAction,
    this.isFinished = false,
  });

  final EventSummary summary;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _fmtDate(summary.lastUpdatedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isFinished)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'せいさんOK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    summary.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'さんか ${summary.participantIds.length} にん',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtYen(summary.totalUnsettledAmount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isFinished && onAction != null)
                  IconButton(
                    onPressed: onAction,
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.message, required this.theme});
  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
      ),
    );
  }
}

class _CreateFab extends StatelessWidget {
  const _CreateFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF13EC80),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
        elevation: 8,
      ),
      icon: const Icon(Icons.add, size: 28, color: Color(0xFF102219)),
      label: const Text(
        'あたらしくつくる',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102219)),
      ),
    );
  }
}
