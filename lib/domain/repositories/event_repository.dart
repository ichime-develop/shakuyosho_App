import 'package:shakuyousho_app/domain/models/event_meta_model.dart';

/// イベント（借用書）データへのアクセスを抽象化するリポジトリインターフェース
abstract class EventRepository {
  /// すべてのイベントメタを取得
  List<EventMeta> getAllEventMetas();

  /// IDでイベントメタを取得
  EventMeta? getEventMetaById(String eventId);

  /// イベントメタを作成または更新
  void upsertEventMeta(EventMeta meta);

  /// イベントメタを削除
  void deleteEventMeta(String eventId);
}
