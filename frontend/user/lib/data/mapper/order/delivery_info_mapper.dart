import 'package:b2205946_duonghuuluan_luanvan/data/models/order/delivery_info_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/delivery_info.dart';

class DeliveryInfoMapper {
  static DeliveryInfo fromModel(DeliveryInfoModel model) {
    return DeliveryInfo(
      id: model.id,
      userId: model.userId,
      name: model.name,
      address: model.address,
      phone: model.phone,
      districtId: model.districtId,
      wardCode: model.wardCode,
    );
  }
}
