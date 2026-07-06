import 'package:b2205946_duonghuuluan_luanvan/data/models/order/ghn_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/ghn_models.dart';

class GhnMapper {
  static List<GhnProvince> provinces(List<GhnProvinceModel> models) {
    return models
        .map((m) => GhnProvince(provinceId: m.provinceId, provinceName: m.provinceName))
        .toList();
  }

  static List<GhnDistrict> districts(List<GhnDistrictModel> models) {
    return models
        .map((m) => GhnDistrict(districtId: m.districtId, districtName: m.districtName))
        .toList();
  }

  static List<GhnWard> wards(List<GhnWardModel> models) {
    return models.map((m) => GhnWard(wardCode: m.wardCode, wardName: m.wardName)).toList();
  }

  static List<GhnServiceOption> services(List<GhnServiceOptionModel> models) {
    return models
        .map((m) => GhnServiceOption(
              serviceId: m.serviceId,
              serviceTypeId: m.serviceTypeId,
              shortName: m.shortName,
            ))
        .toList();
  }

  static GhnFee fee(GhnFeeModel model) {
    return GhnFee(total: model.total, serviceFee: model.serviceFee, insuranceFee: model.insuranceFee);
  }

  static GhnShipment shipment(GhnShipmentModel model) {
    return GhnShipment(
      id: model.id,
      orderId: model.orderId,
      ghnOrderCode: model.ghnOrderCode,
      status: model.status,
      shippingFee: model.shippingFee,
    );
  }
}
