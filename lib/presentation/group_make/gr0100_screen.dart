import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/data/mock/users_mock.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';

/// GR0100: グループ作成／招待画面（作成者向け・モック）
///
/// - グループ名入力
/// - 友達検索＋チェック選択
/// - 「グループをつくる」押下で
///   1) Thread作成
///   2) EventMeta作成
///   3) EV0200へ遷移
class Gr0100GroupCreateScreen extends ConsumerStatefulWidget {
  const Gr0100GroupCreateScreen({super.key});

  @override
  ConsumerState<Gr0100GroupCreateScreen> createState() =>
      _Gr0100GroupCreateScreenState();
}

class _Gr0100GroupCreateScreenState
    extends ConsumerState<Gr0100GroupCreateScreen> {
  final _groupNameCtrl = TextEditingController(text: '');
  final _friendSearchCtrl = TextEditingController();

  /// 選択中の友達ID
  final Set<String> _selectedFriendIds = {};

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    _friendSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // HTMLの淡いベージュ系に寄せた配色（必要ならアプリテーマへ寄せる）
    const bg = Color(0xFFFDFDF6);
    const surface = Color(0xFFF4F4EE);
    const textMain = Color(0xFF4A4F4B);
    const textSub = Color(0xFF8B9690);
    const primary = Color(0xFF36E28C);
    const primaryContent = Color(0xFF111714);

    final groupName = _groupNameCtrl.text.trim();
    final canCreate = groupName.isNotEmpty;

    final friendQuery = _friendSearchCtrl.text.trim();
    final friends = mockUsers.where((f) => f.userId != currentUserId).toList();
    final filteredFriends = friendQuery.isEmpty
        ? friends
        : friends
              .where((f) => f.displayName.contains(friendQuery))
              .toList(growable: false);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: bg,
        elevation: 0,
        leading: IconButton(
          tooltip: 'もどる',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text(
          'グループをつくる／しょうたい',
          style: TextStyle(fontWeight: FontWeight.w800, color: textMain),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Scroll area
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const SizedBox(height: 8),

              // --- Group creation section ---
              const _SectionLabel('グループのなまえ'),
              const SizedBox(height: 8),
              TextField(
                controller: _groupNameCtrl,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  color: textMain,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'りょこう、BBQなど',
                  hintStyle: const TextStyle(color: textSub),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: primary, width: 2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: canCreate ? _onCreateGroup : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: primaryContent,
                    shape: const StadiumBorder(),
                    disabledBackgroundColor: primary.withOpacity(0.35),
                    disabledForegroundColor: primaryContent.withOpacity(0.7),
                  ),
                  icon: const Icon(Icons.add_circle),
                  label: const Text(
                    'グループをつくる',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Container(height: 1, color: surface),
              const SizedBox(height: 18),

              // --- Friends section ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ともだちをさがす',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: textMain,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${friends.length}人',
                      style: const TextStyle(
                        color: textSub,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _friendSearchCtrl,
                style: const TextStyle(
                  color: textMain,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'なまえでさがす',
                  hintStyle: const TextStyle(color: textSub),
                  filled: true,
                  fillColor: surface,
                  prefixIcon: const Icon(Icons.search, color: textSub),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: primary, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),

              _FriendList(
                friends: filteredFriends,
                onToggle: (friendId) {
                  setState(() {
                    if (_selectedFriendIds.contains(friendId)) {
                      _selectedFriendIds.remove(friendId);
                    } else {
                      _selectedFriendIds.add(friendId);
                    }
                  });
                },
                isChecked: (friendId) => _selectedFriendIds.contains(friendId),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onCreateGroup() async {
    final name = _groupNameCtrl.text.trim();
    if (name.isEmpty) return;

    final memberIds = _selectedFriendIds.toList(growable: false);
    final now = DateTime.now();
    final threadId = generateId(prefix: 'th');
    final eventId = generateId(prefix: 'ev');
    final participants = <String>{
      ...memberIds,
      currentUserId,
    }.toList(growable: false);
    final thread = Thread(
      id: threadId,
      type: 'group',
      title: name,
      participantIds: participants,
      createdAt: now,
      updatedAt: now,
    );
    ref.read(threadListProvider.notifier).upsert(thread);
    final eventMeta = EventMeta(
      id: eventId,
      title: name,
      participantIds: participants,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );
    ref.read(eventMetaListProvider.notifier).upsertEventMeta(eventMeta);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('グループをつくりました')));

    final router = GoRouter.of(context);
    router.go('/ev0100');
    Future.microtask(() {
      router.push('/ev0200/$eventId');
    });
  }
}

/// ---------------------------
/// Widgets
/// ---------------------------
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4A4F4B),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final MockUser friend;
  final bool checked;
  final VoidCallback onToggle;

  const _FriendTile({
    required this.friend,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const textMain = Color(0xFF4A4F4B);
    const textSub = Color(0xFF8B9690);
    final avatarColors = _avatarColorsFor(friend.userId);

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarColors.background,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                friend.displayName.characters.first,
                style: TextStyle(
                  color: avatarColors.foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMain,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ともだち',
                    style: const TextStyle(
                      color: textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _CircleCheckbox(checked: checked, onTap: onToggle),
          ],
        ),
      ),
    );
  }
}

class _FriendList extends StatelessWidget {
  const _FriendList({
    required this.friends,
    required this.onToggle,
    required this.isChecked,
  });

  final List<MockUser> friends;
  final ValueChanged<String> onToggle;
  final bool Function(String) isChecked;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();
    return Column(
      children: List.generate(friends.length * 2 - 1, (index) {
        if (index.isOdd) {
          return Divider(height: 1, color: Colors.grey.shade200);
        }
        final friend = friends[index ~/ 2];
        return _FriendTile(
          friend: friend,
          checked: isChecked(friend.userId),
          onToggle: () => onToggle(friend.userId),
        );
      }),
    );
  }
}

class _CircleCheckbox extends StatelessWidget {
  final bool checked;
  final VoidCallback onTap;

  const _CircleCheckbox({required this.checked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF36E28C);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? primary : Colors.transparent,
                border: Border.all(
                  color: checked ? primary : const Color(0xFFBDBDBD),
                  width: 2,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: checked ? 1 : 0,
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------
/// モックデータ
/// ---------------------------
class _AvatarColors {
  const _AvatarColors(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

const List<_AvatarColors> _avatarPalette = [
  _AvatarColors(Color(0xFFE0F2F1), Color(0xFF2E7D32)),
  _AvatarColors(Color(0xFFFFF3E0), Color(0xFFEF6C00)),
  _AvatarColors(Color(0xFFF3E5F5), Color(0xFF7B1FA2)),
  _AvatarColors(Color(0xFFE3F2FD), Color(0xFF1565C0)),
  _AvatarColors(Color(0xFFFCE4EC), Color(0xFFC2185B)),
  _AvatarColors(Color(0xFFE8F5E9), Color(0xFF2E7D32)),
  _AvatarColors(Color(0xFFE1F5FE), Color(0xFF0277BD)),
];

_AvatarColors _avatarColorsFor(String userId) {
  if (userId.isEmpty) return _avatarPalette.first;
  final idx =
      userId.codeUnits.fold<int>(0, (p, v) => p + v) % _avatarPalette.length;
  return _avatarPalette[idx];
}
