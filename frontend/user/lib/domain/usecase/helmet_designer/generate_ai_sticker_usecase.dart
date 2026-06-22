import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/helmet_designer/helmet_designer_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';

class GenerateAiStickerUseCase {
  final HelmetDesignerRepository _repo;
  GenerateAiStickerUseCase(this._repo);
  Future<Either<Failure, StickerTemplate>> call(AiStickerRequest request) => _repo.generateAiSticker(request);
}
