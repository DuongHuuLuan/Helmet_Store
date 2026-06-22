import 'package:b2205946_duonghuuluan_luanvan/data/models/category/category_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/category/category.dart';

class CategoryMapper {
  static Category fromModel(CategoryModel model) {
    return Category(id: model.id, name: model.name);
  }

  static Map<String, dynamic> toJson(Category entity) {
    return {"id": entity.id, "name": entity.name};
  }
}
