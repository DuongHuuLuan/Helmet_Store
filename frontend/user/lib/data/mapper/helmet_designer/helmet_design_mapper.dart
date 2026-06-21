import 'package:b2205946_duonghuuluan_luanvan/data/mapper/helmet_designer/sticker_layer_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/helmet_designer/helmet_design_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';

class HelmetDesignMapper {
  static HelmetDesign fromModel(HelmetDesignModel model) {
    return HelmetDesign(
      id: model.id ?? 0,
      helmetProductId: model.helmetProductId ?? 0,
      productDetailId: model.productDetailId,
      helmetName: model.helmetName ?? "",
      helmetBaseImageUrl: model.helmetBaseImageUrl ?? "",
      stickers: (model.stickers ?? []).map(StickerLayerMapper.fromModel).toList(),
      isShared: model.isShared ?? false,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  static Map<String, dynamic> toJson(HelmetDesign entity) {
    return {
      "id": entity.id,
      "helmet_product_id": entity.helmetProductId,
      "product_detail_id": entity.productDetailId,
      "helmet_name": entity.helmetName,
      "helmet_base_image_url": entity.helmetBaseImageUrl,
      "stickers": entity.stickers.map(StickerLayerMapper.toJson).toList(),
      "is_shared": entity.isShared,
    };
  }
}
