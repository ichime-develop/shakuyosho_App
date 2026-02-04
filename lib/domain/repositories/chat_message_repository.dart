import '../models/chat_message_model.dart';

/// チャットメッセージの永続化インターフェース
abstract class ChatMessageRepository {
  /// 全メッセージを取得（論理削除除く）
  List<ChatMessage> getAll();

  /// threadId で絞り込んだメッセージを取得（論理削除除く）
  List<ChatMessage> getByThreadId(String threadId);

  /// ID で1件取得
  ChatMessage? getById(String id);

  /// 新規作成または更新
  Future<void> upsert(ChatMessage message);

  /// 論理削除
  Future<void> delete(String id);

  /// 新規ID生成
  String newId();
}
