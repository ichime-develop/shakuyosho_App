import 'package:shakuyousho_app/domain/models/event_meta_model.dart';

/// 独立した EventMeta モックデータ
/// Thread とは相互参照しない（完全分離）
final List<EventMeta> mockEventMetas = List<EventMeta>.unmodifiable([
  EventMeta(
    id: 'ev_001',
    title: '箱根旅行',
    participantIds: ['u_001', 'u_002', 'u_003', 'u_004'],
    createdAt: DateTime(2024, 4, 10, 10, 0),
    updatedAt: DateTime(2024, 4, 12, 18, 30),
  ),
  EventMeta(
    id: 'ev_002',
    title: 'サマーフェス',
    participantIds: ['u_001', 'u_005'],
    createdAt: DateTime(2024, 5, 18, 9, 30),
    updatedAt: DateTime(2024, 5, 20, 20, 45),
  ),
  EventMeta(
    id: 'ev_003',
    title: '秋キャンプ',
    participantIds: ['u_001', 'u_002', 'u_003', 'u_006'],
    createdAt: DateTime(2024, 6, 2, 8, 0),
    updatedAt: DateTime(2024, 6, 4, 19, 10),
  ),
  EventMeta(
    id: 'ev_004',
    title: 'タパスパーティー',
    participantIds: ['u_001', 'u_007', 'u_008'],
    createdAt: DateTime(2024, 7, 14, 12, 0),
    updatedAt: DateTime(2024, 7, 14, 22, 5),
  ),
  EventMeta(
    id: 'ev_005',
    title: 'お花見ピクニック',
    participantIds: ['u_001', 'u_003', 'u_005', 'u_009'],
    createdAt: DateTime(2024, 3, 28, 11, 0),
    updatedAt: DateTime(2024, 3, 30, 16, 20),
  ),
  EventMeta(
    id: 'ev_006',
    title: '沖縄旅行',
    participantIds: ['u_001', 'u_004', 'u_006', 'u_008', 'u_010'],
    createdAt: DateTime(2024, 8, 9, 9, 0),
    updatedAt: DateTime(2024, 8, 12, 21, 45),
  ),
  EventMeta(
    id: 'ev_007',
    title: '温泉チーム',
    participantIds: ['u_001', 'u_002', 'u_003', 'u_004', 'u_005', 'u_006'],
    createdAt: DateTime(2024, 9, 1, 8, 0),
    updatedAt: DateTime(2024, 9, 3, 20, 0),
  ),
  EventMeta(
    id: 'ev_008',
    title: 'BBQ会',
    participantIds: ['u_001', 'u_003', 'u_007', 'u_009', 'u_010'],
    createdAt: DateTime(2024, 9, 15, 11, 0),
    updatedAt: DateTime(2024, 9, 15, 19, 30),
  ),
]);
