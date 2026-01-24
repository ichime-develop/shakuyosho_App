import 'package:shakuyousho_app/domain/models/group_model.dart';

/// グループデータへのアクセスを抽象化するリポジトリインターフェース
abstract class GroupRepository {
  /// すべてのグループを取得
  List<Group> getAllGroups();

  /// IDでグループを取得
  Group? getGroupById(String id);

  /// 新しいグループを作成
  void create(Group group);
}
