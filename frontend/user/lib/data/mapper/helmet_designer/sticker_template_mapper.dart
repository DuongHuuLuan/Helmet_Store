import 'package:b2205946_duonghuuluan_luanvan/data/models/helmet_designer/sticker_template_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';

class StickerTemplateMapper {
  static StickerTemplate fromModel(StickerTemplateModel model) {
    return StickerTemplate(
      id: model.id,
      name: model.name,
      imageUrl: model.imageUrl,
      category: model.category ?? "",
      isAiGenerated: model.isAiGenerated ?? false,
      hasTransparentBackground: model.hasTransparentBackground ?? false,
    );
  }
}
