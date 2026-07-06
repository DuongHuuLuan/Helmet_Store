import 'package:b2205946_duonghuuluan_luanvan/data/models/order/payment_method_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/payment_method.dart';

class PaymentMethodMapper {
  static PaymentMethod fromModel(PaymentMethodModel model) {
    return PaymentMethod(id: model.id, name: model.name);
  }
}
