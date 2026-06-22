class Discount {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final double percent;
  final DateTime startAt;
  final DateTime endAt;
  final String status;

  const Discount({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.percent,
    required this.startAt,
    required this.endAt,
    required this.status,
  });
}
