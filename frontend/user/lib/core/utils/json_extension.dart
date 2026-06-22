extension JsonParsingX on Object? {
  int toInt() {
    if (this is num) return (this as num).toInt();
    return int.tryParse(toString()) ?? 0;
  }

  double toDouble() {
    if (this is num) return (this as num).toDouble();
    return double.tryParse(toString()) ?? 0.0;
  }

  DateTime? toDateTime() {
    if (this == null) return null;
    return DateTime.tryParse(toString());
  }
}
