import 'package:b2205946_duonghuuluan_luanvan/data/models/helmet_designer/sticker_crop_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_crop.dart';

class StickerCropMapper {
  static StickerCrop fromModel(StickerCropModel model) {
    return StickerCrop(
      left: model.left ?? 0,
      top: model.top ?? 0,
      right: model.right ?? 1,
      bottom: model.bottom ?? 1,
    );
  }

  static Map<String, dynamic> toJson(StickerCrop crop) {
    return {
      "left": crop.left,
      "top": crop.top,
      "right": crop.right,
      "bottom": crop.bottom,
    };
  }
}
