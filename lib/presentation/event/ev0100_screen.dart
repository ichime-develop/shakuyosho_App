import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/presentation/common/common_bottom_nav_bar.dart';

/// EV0100: イベント一覧画面
/// - 旅行・飲み会などのイベント単位で、貸し借りを管理する入り口
/// - 各イベントの概要と「詳細(EV0200)」「精算(SV0100)」への導線を提供
class Ev0100EventListScreen extends ConsumerStatefulWidget {
  const Ev0100EventListScreen({super.key});

  @override
  ConsumerState<Ev0100EventListScreen> createState() =>
      _Ev0100EventListScreenState();
}

class _Ev0100EventListScreenState
    extends ConsumerState<Ev0100EventListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metas = ref
        .watch(eventMetaListProvider)
        .where((meta) => meta.deletedAt == null)
        .toList(growable: false);
    final query = _searchQuery.trim().toLowerCase();
    final filteredMetas = query.isEmpty
        ? metas
        : metas
            .where((meta) => meta.title.toLowerCase().contains(query))
            .toList(growable: false);
    final views = filteredMetas
        .map((meta) {
          final txs = ref.watch(transactionsByEventProvider(meta.id));
          final summary = deriveEventSummary(meta, txs);
          return _EventView(meta: meta, summary: summary);
        })
        .toList(growable: false);
    final ongoing = views.where((e) => !e.summary.isSettled).toList()
      ..sort(
        (a, b) => b.summary.lastUpdatedAt.compareTo(a.summary.lastUpdatedAt),
      );
    final finished = views.where((e) => e.summary.isSettled).toList()
      ..sort(
        (a, b) => b.summary.lastUpdatedAt.compareTo(a.summary.lastUpdatedAt),
      );

    return Scaffold(
      appBar: AppBar(title: const Text('EV0100 イベント一覧'), centerTitle: false),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: CupertinoSearchTextField(
                    placeholder: 'けんさく',
                    style: const TextStyle(),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim());
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 140),
                    children: [
                      if (views.isEmpty)
                        _EmptyMessage(
                          message: query.isEmpty
                              ? 'イベントはまだありません。'
                              : 'けんさく けっかがないよ。',
                          theme: theme,
                        )
                      else ...[
                        _SectionHeader(
                          label: 'しんこうちゅう',
                          accentColor: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        if (ongoing.isEmpty)
                          _EmptyMessage(
                            message: 'まだしんこうちゅうのイベントはないよ。',
                            theme: theme,
                          )
                        else
                          _EventList(
                            themes: theme,
                            events: ongoing,
                            onTap: (e) =>
                                _Controller.goDetail(context, e.meta.id),
                            onAction: (e) =>
                                _Controller.goSettlement(context, e.meta.id),
                          ),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          label: 'せいさんずみ',
                          accentColor: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        if (finished.isEmpty)
                          _EmptyMessage(
                            message: 'せいさんずみのイベントはまだありません。',
                            theme: theme,
                          )
                        else
                          _EventList(
                            themes: theme,
                            events: finished,
                            isFinished: true,
                            onTap: (e) =>
                                _Controller.goDetail(context, e.meta.id),
                          ),
                      ],
                    ],
                  ),
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

class _EventView {
  const _EventView({required this.meta, required this.summary});

  final EventMeta meta;
  final EventDerivedSummary summary;
}

class _Controller {
  static void goDetail(BuildContext context, String eventId) {
    context.push('/ev0200/$eventId');
  }

  static void goSettlement(BuildContext context, String eventId) {
    context.push('/sv0100/$eventId');
  }

  static void onCreateEvent(BuildContext context) {
    context.push('/ev0101');
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.accentColor});

  final String label;
  final Color accentColor;

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
  final List<_EventView> events;
  final bool isFinished;
  final void Function(_EventView) onTap;
  final void Function(_EventView)? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        return Column(
          children: [
            _EventRow(
              summary: event.summary,
              meta: event.meta,
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
    required this.meta,
    required this.theme,
    required this.onTap,
    this.onAction,
    this.isFinished = false,
  });

  final EventDerivedSummary summary;
  final EventMeta meta;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback? onAction;
  final bool isFinished;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
        child: Opacity(
          opacity: isFinished ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
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
                    meta.title,
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
                if (!isFinished && onAction != null)
                  IconButton(
                    onPressed: onAction,
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                if (isFinished || onAction == null)
                  const SizedBox(height: 0, width: 0),
              ],
              ),
            ],
          ),
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
