import 'package:hive/hive.dart';

import '../../domain/models/chat_message_model.dart';
import '../../domain/repositories/chat_message_repository.dart';

/// Hive 実装の ChatMessageRepository（Map保存）
class HiveChatMessageRepository implements ChatMessageRepository {
  HiveChatMessageRepository({required Box<Map> messageBox}) : _box = messageBox;

  final Box<Map> _box;

  Map<String, dynamic> _castMap(Map raw) => Map<String, dynamic>.from(raw);

  @override
  List<ChatMessage> getAll() {
    final result = <ChatMessage>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      final msg = ChatMessage.fromMap(_castMap(raw), id: key.toString());
      if (msg.deletedAt != null) continue;
      result.add(msg);
    }
    return result;
  }

  @override
  List<ChatMessage> getByThreadId(String threadId) {
    return getAll().where((m) => m.threadId == threadId).toList();
  }

  @override
  ChatMessage? getById(String id) {
    final raw = _box.get(id);
    if (raw == null) return null;
    return ChatMessage.fromMap(_castMap(raw), id: id);
  }

  @override
  Future<void> upsert(ChatMessage message) async {
    await _box.put(message.id, message.toMap());
  }

  @override
  Future<void> delete(String id) async {
    final existing = getById(id);
    if (existing == null) return;
    final updated = existing.copyWith(deletedAt: DateTime.now());
    await _box.put(id, updated.toMap());
  }

  @override
  String newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
