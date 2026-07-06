extension CurrencyX on double {
  String toVnd() {
    final s = toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final left = s.length - i;
      buf.write(s[i]);
      if (left > 1 && left % 3 == 1) buf.write(".");
    }
    return "$buf đ";
  }
}
