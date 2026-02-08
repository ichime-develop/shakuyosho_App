/// DateTime拡張(日付フォーマッター)
extension DateTimeExtension on DateTime {
  String _two(int n) => n.toString().padLeft(2, '0');

  /// Example: 2025/01/09
  String toYmdSlash() => '$year/${_two(month)}/${_two(day)}';

  /// Example: 1/09
  String toMdSlash() => '$month/${_two(day)}';

  /// Example: 2025ねん 1がつ 9にち
  String toYmdJa() => '$yearねん $monthがつ $dayにち';

  /// Example: 2025/01/09 18:05
  String toYmdHm() => '${toYmdSlash()} ${_two(hour)}:${_two(minute)}';
}
