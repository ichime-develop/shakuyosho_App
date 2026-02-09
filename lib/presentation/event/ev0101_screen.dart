import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shakuyousho_app/application/providers/event_providers.dart';
import 'package:shakuyousho_app/domain/models/event_meta_model.dart';
import 'package:shakuyousho_app/domain/models/thread_model.dart';
import 'package:shakuyousho_app/presentation/common/app_styles.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_dialog.dart';
import 'package:shakuyousho_app/presentation/common/error/app_error_mapper.dart';
import 'package:shakuyousho_app/presentation/common/error/app_messages.dart';

/// EV0101: イベント新規作成画面（作成者向け・モック）
///
/// - イベント名入力
/// - 友達検索＋チェック選択
/// - 「イベントをつくる」押下で
///   1) Thread作成
///   2) EventMeta作成
///   3) EV0200へ遷移
class Ev0101EventCreateScreen extends ConsumerStatefulWidget {
  const Ev0101EventCreateScreen({super.key});

  @override
  ConsumerState<Ev0101EventCreateScreen> createState() =>
      _Ev0101EventCreateScreenState();
}

class _Ev0101EventCreateScreenState
    extends ConsumerState<Ev0101EventCreateScreen> {
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
    final theme = Theme.of(context);

    final groupName = _groupNameCtrl.text.trim();
    final canCreate = groupName.isNotEmpty;

    final friendQuery = _friendSearchCtrl.text.trim();
    final myId = ref.watch(currentUserIdProvider);
    List<User> allUsers;
    try {
      allUsers = ref
          .watch(userListProvider)
          .where((u) => u.id != myId && u.deletedAt == null)
          .toList();
    } catch (e, st) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final err = toAppError(e, st);
        await showAppErrorDialog(context: context, error: err);
      });
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'もどる',
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new),
          ),
          title: Text(
            'イベントをつくる／しょうたい',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: AppTextSizes.title,
                  fontWeight: AppFontWeights.appBarTitle,
                ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            AppMessages.dialog(AppMessageId.s004).message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: AppTextSizes.body,
              color: theme.hintColor,
            ),
          ),
        ),
      );
    }
    final filteredFriends = friendQuery.isEmpty
        ? allUsers
        : allUsers
              .where((f) => f.displayName.contains(friendQuery))
              .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'もどる',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Text(
          'イベントをつくる／しょうたい',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: AppTextSizes.title,
                fontWeight: AppFontWeights.appBarTitle,
              ),
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

              // --- Event creation section ---
              const _SectionLabel('イベントのなまえ'),
              const SizedBox(height: 8),
              TextField(
                controller: _groupNameCtrl,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppTextSizes.body,
                  fontWeight: AppFontWeights.listSubtitle,
                  color: const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'りょこう、BBQなど',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    fontSize: AppTextSizes.small,
                    color: AppColors.iconDefault,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    borderSide: const BorderSide(color: AppColors.listBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    borderSide: const BorderSide(color: AppColors.listBorder),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: canCreate ? _onCreateGroup : null,
                  style: AppButtonStyles.primaryPill,
                  icon: const Icon(Icons.add_circle),
                  label: Text(
                    'イベントをつくる',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: AppTextSizes.body,
                      fontWeight: AppFontWeights.label,
                      color: AppColors.primaryActionText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Container(height: 1, color: AppColors.listBorder),
              const SizedBox(height: 18),

              // --- Friends section ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ともだちをさがす',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: AppTextSizes.section,
                      fontWeight: AppFontWeights.sectionTitle,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.addButtonBackground,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: AppColors.listBorder),
                    ),
                    child: Text(
                      '${allUsers.length}人',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.iconDefault,
                        fontWeight: AppFontWeights.listSubtitle,
                        fontSize: AppTextSizes.small,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _friendSearchCtrl,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppTextSizes.body,
                  fontWeight: AppFontWeights.listSubtitle,
                  color: const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  hintText: 'なまえでさがす',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    fontSize: AppTextSizes.small,
                    color: AppColors.iconDefault,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.iconDefault,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    borderSide: const BorderSide(color: AppColors.listBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    borderSide: const BorderSide(color: AppColors.listBorder),
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
      ref.read(currentUserIdProvider),
    }.toList(growable: false);
    final thread = Thread(
      id: threadId,
      type: 'group',
      title: name,
      participantIds: participants,
      createdAt: now,
      updatedAt: now,
    );
    try {
      ref.read(threadListProvider.notifier).upsert(thread);
    } catch (e, st) {
      final err = toAppError(e, st);
      if (!mounted) return;
      await showAppErrorDialog(context: context, error: err);
      return;
    }
    final eventMeta = EventMeta(
      id: eventId,
      title: name,
      participantIds: participants,
      createdAt: now,
      updatedAt: now,
      status: EventStatus.inProgress,
      deletedAt: null,
    );
    try {
      await ref.read(eventMetaListProvider.notifier).upsertEventMeta(eventMeta);
    } catch (e, st) {
      final err = toAppError(e, st);
      if (!mounted) return;
      await showAppErrorDialog(context: context, error: err);
      return;
    }
    if (!mounted) return;
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: AppTextSizes.small,
              fontWeight: AppFontWeights.sectionTitle,
              color: AppColors.iconDefault,
            ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final User friend;
  final bool checked;
  final VoidCallback onToggle;

  const _FriendTile({
    required this.friend,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColors = _avatarColorsFor(friend.id);
    final theme = Theme.of(context);

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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: avatarColors.foreground,
                      fontSize: AppTextSizes.section,
                      fontWeight: AppFontWeights.listTitle,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: AppTextSizes.section,
                      fontWeight: AppFontWeights.listTitle,
                      color: const Color(0xFF111827),
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

  final List<User> friends;
  final ValueChanged<String> onToggle;
  final bool Function(String) isChecked;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();
    return Column(
      children: List.generate(friends.length * 2 - 1, (index) {
        if (index.isOdd) {
          return const Divider(height: 1, color: AppColors.listBorder);
        }
        final friend = friends[index ~/ 2];
        return _FriendTile(
          friend: friend,
          checked: isChecked(friend.id),
          onToggle: () => onToggle(friend.id),
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
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.selectionActive : Colors.white,
                border: Border.all(
                  color: checked
                      ? AppColors.selectionActive
                      : AppColors.selectionBorder,
                  width: 1.6,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: checked ? 1 : 0,
              child: const Icon(
                Icons.check,
                size: 12,
                color: AppColors.selectionCheck,
              ),
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
