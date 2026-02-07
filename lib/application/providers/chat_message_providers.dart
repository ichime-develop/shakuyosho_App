import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/mock/fr_chat_messages_mock.dart';
import '../../domain/models/chat_message_model.dart';
import 'package:shakuyousho_app/application/providers/user_providers.dart';
import '../../domain/repositories/chat_message_repository.dart';
import '../../infrastructure/repositories/hive_chat_message_repository.dart';

// ────────────────────────────────────────────────────────────────
// Hive Box
// ────────────────────────────────────────────────────────────────
final Box<Map> _messageBox = Hive.box<Map>('messages');

// ────────────────────────────────────────────────────────────────
// Seed（初回のみモックデータを投入）
// ────────────────────────────────────────────────────────────────
void _seedMessagesIfEmpty({required Box<Map> box}) {
  final hasLive = box.values.any((raw) {
    final map = Map<String, dynamic>.from(raw);
    return ChatMessage.fromMap(map).deletedAt == null;
  });
  if (hasLive) return;

  // モックデータを投入
  final mockMessages = mockChatMessages();
  for (int i = 0; i < mockMessages.length; i++) {
    final m = mockMessages[i];
    final id = '${DateTime.now().microsecondsSinceEpoch}_$i';
    final msg = ChatMessage(
      id: id,
      threadId: m.friendId, // 1対1なので friendId = threadId
      senderId: m.isMe ? currentUserId : m.friendId,
      text: m.text,
      createdAt: m.createdAt,
    );
    box.put(id, msg.toMap());
  }
}

// ────────────────────────────────────────────────────────────────
// Repository Provider
// ────────────────────────────────────────────────────────────────
final chatMessageRepositoryProvider = Provider<ChatMessageRepository>((ref) {
  _seedMessagesIfEmpty(box: _messageBox);
  return HiveChatMessageRepository(messageBox: _messageBox);
});

// ────────────────────────────────────────────────────────────────
// Message Providers
// ────────────────────────────────────────────────────────────────

/// 全メッセージ一覧
final allMessagesProvider = Provider<List<ChatMessage>>((ref) {
  final repo = ref.watch(chatMessageRepositoryProvider);
  return repo.getAll();
});

/// threadId（= friendId）で絞り込んだメッセージ一覧
final messagesByThreadProvider = Provider.family<List<ChatMessage>, String>((
  ref,
  threadId,
) {
  final repo = ref.watch(chatMessageRepositoryProvider);
  return repo.getByThreadId(threadId);
});

// ────────────────────────────────────────────────────────────────
// Actions（書き込み用 Notifier）
// ────────────────────────────────────────────────────────────────
final chatMessageActionsProvider =
    NotifierProvider<ChatMessageActionsNotifier, void>(
      ChatMessageActionsNotifier.new,
    );

class ChatMessageActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  ChatMessageRepository get _repo => ref.read(chatMessageRepositoryProvider);

  /// メッセージを送信
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String senderId,
    required String text,
  }) async {
    final id = _repo.newId();
    final msg = ChatMessage(
      id: id,
      threadId: threadId,
      senderId: senderId,
      text: text,
      createdAt: DateTime.now(),
    );
    await _repo.upsert(msg);
    ref.invalidate(allMessagesProvider);
    ref.invalidate(messagesByThreadProvider(threadId));
    return msg;
  }

  /// メッセージを削除（論理削除）
  Future<void> deleteMessage(String id) async {
    final existing = _repo.getById(id);
    await _repo.delete(id);
    if (existing != null) {
      ref.invalidate(messagesByThreadProvider(existing.threadId));
    }
    ref.invalidate(allMessagesProvider);
  }
}
