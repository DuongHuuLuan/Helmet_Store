import 'package:b2205946_duonghuuluan_luanvan/data/models/discount/discount_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';

class DiscountMapper {
  static Discount fromModel(DiscountModel model) {
    return Discount(
      id: model.id,
      categoryId: model.categoryId,
      name: model.name,
      description: model.description ?? "",
      percent: model.percent,
      startAt: model.startAt ?? DateTime(1970),
      endAt: model.endAt ?? DateTime(1970),
      status: model.status ?? "",
    );
  }
}
