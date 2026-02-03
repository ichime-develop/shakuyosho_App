/// 貸借の向き
enum LoanDirection { lent, borrowed }

/// 申請ステータス
/// pending: しんせいちゅう / approved: しょうにんずみ / rejected: きゃっか
enum LoanStatus { pending, approved, rejected }

/// 返済の1件（承認済みのみ記録）
class Repayment {
  final int amountYen;
  final DateTime paidAt;

  const Repayment({required this.amountYen, required this.paidAt});

  Map<String, dynamic> toMap() => {
    'amountYen': amountYen,
    'paidAtMs': paidAt.millisecondsSinceEpoch,
  };

  static Repayment fromMap(Map<dynamic, dynamic> map) {
    final amountRaw = map['amountYen'];
    final paidAtRaw = map['paidAtMs'];

    final amount = amountRaw is int
        ? amountRaw
        : int.tryParse('$amountRaw') ?? 0;
    final paidAtMs = paidAtRaw is int
        ? paidAtRaw
        : int.tryParse('$paidAtRaw') ?? DateTime.now().millisecondsSinceEpoch;

    return Repayment(
      amountYen: amount,
      paidAt: DateTime.fromMillisecondsSinceEpoch(paidAtMs),
    );
  }

  Repayment copyWith({int? amountYen, DateTime? paidAt}) {
    return Repayment(
      amountYen: amountYen ?? this.amountYen,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}

/// 借用書（坂口モデル準拠）
/// - direction で「かした/かりた」を区別
/// - counterpartyId で相手（友達）を特定
/// - repayments に返済履歴を埋め込み
class Loan {
  final String id;
  final LoanDirection direction;

  /// 相手（友達）のユーザーID
  final String counterpartyId;

  final String _legacyCounterpartyName;

  /// 相手（友達）の名前（後方互換）
  @Deprecated('Use counterpartyId')
  String get counterpartyName => _legacyCounterpartyName;

  /// 元金
  final int amountYen;

  /// 用途
  final String purpose;

  /// 返済期限
  final DateTime dueDate;

  /// 申請状態
  final LoanStatus status;

  /// 作成日
  final DateTime createdAt;

  /// 削除日時（論理削除）
  final DateTime? deletedAt;

  /// 借用書番号（表示用）
  final String iouNo;

  /// 返済履歴（追記のみのイベント）
  final List<Repayment> repayments;

  const Loan({
    required this.id,
    required this.direction,
    required this.counterpartyId,
    String legacyCounterpartyName = '',
    @Deprecated('Use counterpartyId') String? counterpartyName,
    required this.amountYen,
    required this.purpose,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    this.deletedAt,
    required this.iouNo,
    this.repayments = const [],
  }) : _legacyCounterpartyName = counterpartyName ?? legacyCounterpartyName;

  /// 空のLoan（検索結果が無いときのダミー）
  factory Loan.empty() => Loan(
    id: '',
    direction: LoanDirection.lent,
    counterpartyId: '',
    amountYen: 0,
    purpose: '',
    dueDate: DateTime.now(),
    status: LoanStatus.pending,
    createdAt: DateTime.now(),
    deletedAt: null,
    iouNo: '',
    repayments: const [],
  );

  /// 返済合計
  int get repaidYen => repayments.fold<int>(
    0,
    (sum, r) => sum + (r.amountYen < 0 ? 0 : r.amountYen),
  );

  /// 残額
  int get remainingYen => (amountYen - repaidYen).clamp(0, amountYen);

  /// 完済
  bool get isRepaid => amountYen > 0 && remainingYen == 0;

  Map<String, dynamic> toMap() => {
    'id': id,
    'direction': direction.name,
    'counterpartyId': counterpartyId,
    'counterpartyName': _legacyCounterpartyName,
    'amountYen': amountYen,
    'purpose': purpose,
    'dueMs': dueDate.millisecondsSinceEpoch,
    'status': status.name,
    'createdMs': createdAt.millisecondsSinceEpoch,
    'deletedAtMs': deletedAt?.millisecondsSinceEpoch,
    'iouNo': iouNo,
    'repayments': repayments.map((e) => e.toMap()).toList(),
    // 後方互換用
    'isRepaid': isRepaid,
    'repaidYen': repaidYen,
  };

  static Loan fromMap(Map<dynamic, dynamic> map, {String? id}) {
    final resolvedId = id ?? map['id'] as String? ?? '';
    // direction
    final dirStr = map['direction'] as String?;
    final direction = (dirStr != null && dirStr.isNotEmpty)
        ? LoanDirection.values.byName(dirStr)
        : LoanDirection.lent;

    // status（無ければ direction から推定）
    final statusStr = map['status'] as String?;
    final status = statusStr == null
        ? (direction == LoanDirection.borrowed
              ? LoanStatus.pending
              : LoanStatus.approved)
        : LoanStatus.values.byName(statusStr);

    final counterpartyName = (map['counterpartyName'] as String?) ?? '';
    final counterpartyId =
        (map['counterpartyId'] as String?) ??
        (counterpartyName.isNotEmpty ? counterpartyName : 'ゲスト');

    final amountRaw = map['amountYen'];
    final amountYen = amountRaw is int
        ? amountRaw
        : int.tryParse('$amountRaw') ?? 0;

    final purpose = (map['purpose'] as String?) ?? '';

    final dueMsRaw = map['dueMs'];
    final dueMs = dueMsRaw is int
        ? dueMsRaw
        : int.tryParse('$dueMsRaw') ?? DateTime.now().millisecondsSinceEpoch;
    final dueDate = DateTime.fromMillisecondsSinceEpoch(dueMs);

    // createdAt（無ければ dueDate と同じ）
    final createdMsRaw = map['createdMs'];
    final createdMs = createdMsRaw is int
        ? createdMsRaw
        : int.tryParse('$createdMsRaw') ?? dueMs;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(createdMs);

    // iouNo（無ければ id 末尾から生成）
    final iouNo = (map['iouNo'] as String?) ?? _fallbackIouNo(resolvedId);

    // deletedAt
    final deletedAtRaw = map['deletedAtMs'] ?? map['deletedAt'];
    final deletedAt = _dateFromNullable(deletedAtRaw);

    // repayments
    final repayments = <Repayment>[];
    final listRaw = map['repayments'];
    if (listRaw is List) {
      for (final e in listRaw) {
        if (e is Map) repayments.add(Repayment.fromMap(e));
      }
    } else {
      // 旧データ互換
      final legacyRepaid = map['repaidYen'];
      final repaid = legacyRepaid is int
          ? legacyRepaid
          : int.tryParse('$legacyRepaid') ?? 0;
      if (repaid > 0) {
        repayments.add(Repayment(amountYen: repaid, paidAt: createdAt));
      }
    }

    return Loan(
      id: resolvedId,
      direction: direction,
      counterpartyId: counterpartyId,
      legacyCounterpartyName: counterpartyName,
      amountYen: amountYen,
      purpose: purpose,
      dueDate: dueDate,
      status: status,
      createdAt: createdAt,
      deletedAt: deletedAt,
      iouNo: iouNo,
      repayments: repayments,
    );
  }

  Loan copyWith({
    String? id,
    LoanDirection? direction,
    String? counterpartyId,
    String? legacyCounterpartyName,
    @Deprecated('Use counterpartyId') String? counterpartyName,
    int? amountYen,
    String? purpose,
    DateTime? dueDate,
    LoanStatus? status,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? iouNo,
    List<Repayment>? repayments,
  }) {
    return Loan(
      id: id ?? this.id,
      direction: direction ?? this.direction,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      legacyCounterpartyName:
          legacyCounterpartyName ?? counterpartyName ?? _legacyCounterpartyName,
      amountYen: amountYen ?? this.amountYen,
      purpose: purpose ?? this.purpose,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      iouNo: iouNo ?? this.iouNo,
      repayments: repayments ?? this.repayments,
    );
  }
}

String _fallbackIouNo(String id) {
  final tail = id.length <= 4 ? id : id.substring(id.length - 4);
  return 'IOU-$tail';
}

DateTime? _dateFromNullable(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}
