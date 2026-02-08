/// 金額フォーマッター(カンマ付与・通貨記号付与)
extension IntAmountExtension on int {
  String toCommaString() {
    final s = abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final r = s.length - i;
      buf.write(s[i]);
      if (r > 1 && r % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String toYenSymbol() => '¥${toCommaString()}';

  String toAmountWithUnit(String unit) => '${toCommaString()}$unit';
}
