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

/// 借用書
///
/// - lenderUserId : 貸した側（借用書を発行した側）のユーザーID
/// - borrowerUserId : 借りた側のユーザーID
/// - counterpartyId : 相手のユーザーID（getByCounterparty 用。
///   lenderUserId == currentUser なら borrowerUserId、逆なら lenderUserId）
/// - isSettled : 完済フラグ（返済合計 >= 元金 で自動算出）
///
/// direction / LoanStatus は廃止。
class Loan {
  final String id;

  /// 貸した側のユーザーID
  final String lenderUserId;

  /// 借りた側のユーザーID
  final String borrowerUserId;

  /// 相手（友達）のユーザーID（検索・絞り込み用に保持）
  final String counterpartyId;

  /// 元金
  final int amountYen;

  /// 用途
  final String purpose;

  /// 備考（自由記入）
  final String note;

  /// 返済期限
  final DateTime dueDate;

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
    required this.lenderUserId,
    required this.borrowerUserId,
    required this.counterpartyId,
    required this.amountYen,
    required this.purpose,
    this.note = '',
    required this.dueDate,
    required this.createdAt,
    this.deletedAt,
    required this.iouNo,
    this.repayments = const [],
  });

  /// 空のLoan（検索結果が無いときのダミー）
  factory Loan.empty() => Loan(
    id: '',
    lenderUserId: '',
    borrowerUserId: '',
    counterpartyId: '',
    amountYen: 0,
    purpose: '',
    note: '',
    dueDate: DateTime.now(),
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

  /// 完済（返済合計が元金以上）
  bool get isRepaid => amountYen > 0 && remainingYen == 0;

  /// isSettled は isRepaid のエイリアス
  bool get isSettled => isRepaid;

  Map<String, dynamic> toMap() => {
    'id': id,
    'lenderUserId': lenderUserId,
    'borrowerUserId': borrowerUserId,
    'counterpartyId': counterpartyId,
    'amountYen': amountYen,
    'purpose': purpose,
    'note': note,
    'dueMs': dueDate.millisecondsSinceEpoch,
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

    // --- 新フォーマット: lenderUserId / borrowerUserId ---
    var lenderUserId = (map['lenderUserId'] as String?) ?? '';
    var borrowerUserId = (map['borrowerUserId'] as String?) ?? '';

    // --- 旧フォーマット互換: direction + counterpartyId + createdBy ---
    if (lenderUserId.isEmpty && borrowerUserId.isEmpty) {
      final dirStr = (map['direction'] as String?) ?? '';
      final counterparty =
          (map['counterpartyId'] as String?) ??
          (map['counterpartyName'] as String?) ??
          '';
      final createdBy = (map['createdBy'] as String?) ?? '';

      if (dirStr == 'lent') {
        lenderUserId = createdBy.isNotEmpty ? createdBy : 'u_001';
        borrowerUserId = counterparty;
      } else if (dirStr == 'borrowed') {
        lenderUserId = counterparty.isNotEmpty ? counterparty : createdBy;
        borrowerUserId = (createdBy.isNotEmpty && createdBy != counterparty)
            ? createdBy
            : 'u_001';
        if (createdBy == counterparty || createdBy.isEmpty) {
          borrowerUserId = 'u_001';
        }
      } else {
        lenderUserId = createdBy.isNotEmpty ? createdBy : 'u_001';
        borrowerUserId = counterparty;
      }
    }

    final counterpartyId =
        (map['counterpartyId'] as String?) ??
        (map['counterpartyName'] as String?) ??
        '';

    final amountRaw = map['amountYen'];
    final amountYen = amountRaw is int
        ? amountRaw
        : int.tryParse('$amountRaw') ?? 0;

    final purpose = (map['purpose'] as String?) ?? '';
    final note = (map['note'] as String?) ?? '';

    final dueMsRaw = map['dueMs'];
    final dueMs = dueMsRaw is int
        ? dueMsRaw
        : int.tryParse('$dueMsRaw') ?? DateTime.now().millisecondsSinceEpoch;
    final dueDate = DateTime.fromMillisecondsSinceEpoch(dueMs);

    final createdMsRaw = map['createdMs'];
    final createdMs = createdMsRaw is int
        ? createdMsRaw
        : int.tryParse('$createdMsRaw') ?? dueMs;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(createdMs);

    final iouNo = (map['iouNo'] as String?) ?? _fallbackIouNo(resolvedId);

    final deletedAtRaw = map['deletedAtMs'] ?? map['deletedAt'];
    final deletedAt = _dateFromNullable(deletedAtRaw);

    // repayments
    final repaymentsList = <Repayment>[];
    final listRaw = map['repayments'];
    if (listRaw is List) {
      for (final e in listRaw) {
        if (e is Map) repaymentsList.add(Repayment.fromMap(e));
      }
    } else {
      final legacyRepaid = map['repaidYen'];
      final repaid = legacyRepaid is int
          ? legacyRepaid
          : int.tryParse('$legacyRepaid') ?? 0;
      if (repaid > 0) {
        repaymentsList.add(Repayment(amountYen: repaid, paidAt: createdAt));
      }
    }

    return Loan(
      id: resolvedId,
      lenderUserId: lenderUserId,
      borrowerUserId: borrowerUserId,
      counterpartyId: counterpartyId,
      amountYen: amountYen,
      purpose: purpose,
      note: note,
      dueDate: dueDate,
      createdAt: createdAt,
      deletedAt: deletedAt,
      iouNo: iouNo,
      repayments: repaymentsList,
    );
  }

  Loan copyWith({
    String? id,
    String? lenderUserId,
    String? borrowerUserId,
    String? counterpartyId,
    int? amountYen,
    String? purpose,
    String? note,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? deletedAt,
    String? iouNo,
    List<Repayment>? repayments,
  }) {
    return Loan(
      id: id ?? this.id,
      lenderUserId: lenderUserId ?? this.lenderUserId,
      borrowerUserId: borrowerUserId ?? this.borrowerUserId,
      counterpartyId: counterpartyId ?? this.counterpartyId,
      amountYen: amountYen ?? this.amountYen,
      purpose: purpose ?? this.purpose,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
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
