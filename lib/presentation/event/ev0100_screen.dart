import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// EV0100: イベント一覧画面
/// - 旅行・飲み会などのイベント単位で、貸し借りを管理する入り口
/// - 各イベントの概要と「詳細(EV0200)」「精算(SV0100)」への導線を提供
class Ev0100EventListScreen extends ConsumerWidget {
  const Ev0100EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('EV0100 イベントのいちらん'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'りょこうやごはんかいなどのイベントごとに、だれがいくらたてかえたかをゆるくまとめます。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
          const SizedBox(height: 4),

          if (_mockEvents.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('まだイベントがないよ。みぎしたのボタンからつくってみよう（モック）。'),
              ),
            )
          else
            ..._mockEvents.map((e) {
              final total =
                  _mockMembers[e.eventId]?.fold<int>(
                    0,
                    (p, m) => p + m.paidYen,
                  ) ??
                  0;
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    child: Text(
                      e.title.isNotEmpty ? e.title.characters.first : '?',
                    ),
                  ),
                  title: Text(e.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_fmtDate(e.date)} ／ ${e.location}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'さんか: ${e.memberCount}にん ／ みんなではらった: ${_fmtYen(total)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  onTap: () => _Controller.goDetail(context, e.eventId),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      switch (v) {
                        case 'detail':
                          _Controller.goDetail(context, e.eventId);
                          break;
                        case 'settlement':
                          _Controller.goSettlement(context, e.eventId);
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'detail',
                        child: Text('しょうさいをみる(EV0200)'),
                      ),
                      PopupMenuItem(
                        value: 'settlement',
                        child: Text('おかねをまとめる(SV0100)'),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),
          Text(
            '※ イベントのさくせい/へんしゅうはこれから EV0x00 でつくるよ（いまはモック）。',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _Controller.onCreateEvent(context),
        icon: const Icon(Icons.add),
        label: const Text('イベントをつくる（モック）'),
      ),
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
    // TODO: EV0300 (イベント作成) などに繋げる。今はモック。
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('イベントをつくるところはまだだよ（モック）。')));
  }
}

/// ---------------------------
/// モックデータ（EV0200/SV0100 と揃えたイメージ）
/// ---------------------------
class _EventLite {
  final String eventId;
  final String title;
  final DateTime date;
  final String location;
  final int memberCount;

  const _EventLite({
    required this.eventId,
    required this.title,
    required this.date,
    required this.location,
    required this.memberCount,
  });
}

class _EventMember {
  final String userId;
  final String displayName;
  final int paidYen;

  const _EventMember({
    required this.userId,
    required this.displayName,
    required this.paidYen,
  });
}

final _mockEvents = <_EventLite>[
  _EventLite(
    eventId: 'ev_001',
    title: '箱根旅行(2024/05)',
    date: DateTime(2024, 5, 3),
    location: '神奈川・箱根',
    memberCount: 3,
  ),
  _EventLite(
    eventId: 'ev_002',
    title: '夏フェス(2024/08)',
    date: DateTime(2024, 8, 20),
    location: '千葉・幕張',
    memberCount: 2,
  ),
];

final Map<String, List<_EventMember>> _mockMembers = {
  'ev_001': const [
    _EventMember(userId: 'u_ichikawa', displayName: 'いちかわ', paidYen: 12000),
    _EventMember(userId: 'u_sakaguchi', displayName: 'さかぐち', paidYen: 6000),
    _EventMember(userId: 'u_ayaka', displayName: 'あやか', paidYen: 0),
  ],
  'ev_002': const [
    _EventMember(userId: 'u_ichikawa', displayName: 'いちかわ', paidYen: 3000),
    _EventMember(userId: 'u_miki', displayName: 'みき', paidYen: 9000),
  ],
};

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
