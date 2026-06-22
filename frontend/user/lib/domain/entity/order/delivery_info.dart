class DeliveryInfo {
  final int id;
  final int userId;
  final String name;
  final String address;
  final String phone;
  final int? districtId;
  final String? wardCode;

  const DeliveryInfo({
    required this.id,
    required this.userId,
    required this.name,
    required this.address,
    required this.phone,
    this.districtId,
    this.wardCode,
  });
}
