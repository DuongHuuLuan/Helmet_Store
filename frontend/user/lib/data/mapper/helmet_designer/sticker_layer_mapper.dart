import 'package:b2205946_duonghuuluan_luanvan/data/mapper/helmet_designer/sticker_crop_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/helmet_designer/sticker_layer_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_layer.dart';

class StickerLayerMapper {
  static StickerLayer fromModel(StickerLayerModel model) {
    return StickerLayer(
      id: model.id ?? 0,
      stickerId: model.stickerId ?? 0,
      imageUrl: model.imageUrl ?? "",
      x: model.x ?? 0,
      y: model.y ?? 0,
      scale: model.scale ?? 1,
      rotation: model.rotation ?? 0,
      zIndex: model.zIndex ?? 0,
      viewImageKey: model.viewImageKey,
      crop: model.crop != null ? StickerCropMapper.fromModel(model.crop!) : StickerCrop(),
      tintColorValue: model.tintColorValue,
    );
  }

  static Map<String, dynamic> toJson(StickerLayer entity) {
    return {
      "id": entity.id,
      "sticker_id": entity.stickerId,
      "image_url": entity.imageUrl,
      "x": entity.x,
      "y": entity.y,
      "scale": entity.scale,
      "rotation": entity.rotation,
      "z_index": entity.zIndex,
      "view_image_key": entity.viewImageKey,
      "crop": StickerCropMapper.toJson(entity.crop),
      "tint_color_value": entity.tintColorValue,
    };
  }
}
