class GhnProvince {
  final int provinceId;
  final String provinceName;

  const GhnProvince({required this.provinceId, required this.provinceName});
}

class GhnDistrict {
  final int districtId;
  final String districtName;

  const GhnDistrict({required this.districtId, required this.districtName});
}

class GhnWard {
  final String wardCode;
  final String wardName;

  const GhnWard({required this.wardCode, required this.wardName});
}

class GhnServiceOption {
  final int serviceId;
  final int serviceTypeId;
  final String shortName;

  const GhnServiceOption({
    required this.serviceId,
    required this.serviceTypeId,
    required this.shortName,
  });
}

class GhnFee {
  final double total;
  final double? serviceFee;
  final double? insuranceFee;

  const GhnFee({required this.total, this.serviceFee, this.insuranceFee});
}

class GhnShipment {
  final int id;
  final int orderId;
  final String? ghnOrderCode;
  final String? status;
  final double? shippingFee;

  const GhnShipment({
    required this.id,
    required this.orderId,
    this.ghnOrderCode,
    this.status,
    this.shippingFee,
  });
}
