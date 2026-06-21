import 'package:b2205946_duonghuuluan_luanvan/data/models/order/vnpay_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/vnpay.dart';

class VnpayMapper {
  static VnpayPaymentUrl fromModel(VnpayPaymentUrlModel model) {
    return VnpayPaymentUrl(paymentUrl: model.paymentUrl);
  }
}
