import 'package:shakuyousho_app/domain/models/thread_model.dart';

/// スレッドデータへのアクセスを抽象化するリポジトリインターフェース
abstract class ThreadRepository {
  /// すべてのスレッドを取得
  List<Thread> getAll();

  /// IDでスレッドを取得
  Thread? getById(String threadId);

  /// スレッドを作成または更新
  void upsert(Thread thread);
}
