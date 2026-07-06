import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';
import 'package:dartz/dartz.dart';

abstract class HelmetDesignerRepository {
  Future<Either<Failure, List<StickerTemplate>>> getStickerCatalog();

  Future<Either<Failure, String>> transcribeAiStickerVoice(String audioPath);

  Future<Either<Failure, StickerTemplate>> generateAiSticker(AiStickerRequest request);

  Future<Either<Failure, HelmetDesign>> saveDesign(HelmetDesign design);

  Future<Either<Failure, HelmetDesign>> getDesignDetail(int designId);

  Future<Either<Failure, String>> createShareLink(int designId);

  Future<Either<Failure, Unit>> orderDesign(
    int designId, {
    required int productDetailId,
    int quantity = 1,
  });

  Future<Either<Failure, List<HelmetDesign>>> getMyDesigns();
}
