import 'package:b2205946_duonghuuluan_luanvan/data/models/helmet_designer/ai_sticker_request_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/ai_sticker_request.dart';

class AiStickerRequestMapper {
  static AiStickerRequestModel toModel(AiStickerRequest request) {
    return AiStickerRequestModel(
      prompt: request.prompt,
      style: request.style,
      dominantColor: request.dominantColor,
      removeBackground: request.removeBackground,
    );
  }

  static Map<String, dynamic> toJson(AiStickerRequest request) {
    return {
      "prompt": request.prompt,
      "style": request.style,
      "dominant_color": request.dominantColor,
      "remove_background": request.removeBackground,
    };
  }
}
