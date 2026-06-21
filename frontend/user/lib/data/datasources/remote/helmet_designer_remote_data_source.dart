import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/helmet_designer/ai_sticker_request_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/helmet_designer/helmet_design_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/helmet_designer/sticker_template_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/helmet_designer_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class HelmetDesignerRemoteDataSource {
  final HelmetDesignerService _service;

  HelmetDesignerRemoteDataSource(this._service);

  Future<Either<Failure, List<StickerTemplate>>> getStickerCatalog() async {
    try {
      final response = await _service.getStickerCatalog();
      return Right(response.data.map(StickerTemplateMapper.fromModel).toList());
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, StickerTemplate>> generateAiSticker(AiStickerRequest request) async {
    try {
      final response = await _service.generateAiSticker(
        AiStickerRequestMapper.toJson(request),
      );
      return Right(StickerTemplateMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, String>> transcribeAiStickerVoice(String audioPath) async {
    try {
      final audioFile = await MultipartFile.fromFile(audioPath);
      final response = await _service.transcribeAiStickerVoice(audioFile);
      final data = response.data as Map<String, dynamic>;
      final prompt = data["prompt"]?.toString().trim() ??
          data["transcript"]?.toString().trim() ??
          "";
      if (prompt.isEmpty) {
        return Left(Failure(message: "Backend không trả về prompt hợp lệ."));
      }
      return Right(prompt);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, HelmetDesign>> saveDesign(HelmetDesign design) async {
    try {
      final body = HelmetDesignMapper.toJson(design);
      final response = design.id > 0
          ? await _service.updateDesign(design.id, body)
          : await _service.createDesign(body);
      return Right(HelmetDesignMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, HelmetDesign>> getDesignDetail(int designId) async {
    try {
      final response = await _service.getDesignDetail(designId);
      return Right(HelmetDesignMapper.fromModel(response.data));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, String>> createShareLink(int designId) async {
    try {
      final response = await _service.createShareLink(designId);
      final data = response.data as Map<String, dynamic>;
      final shareUrl = data["share_url"]?.toString() ?? data["url"]?.toString();
      if (shareUrl == null || shareUrl.isEmpty) {
        return Left(Failure(message: "Backend không trả về share_url hợp lệ."));
      }
      return Right(shareUrl);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Unit>> orderDesign(
    int designId, {
    required int productDetailId,
    int quantity = 1,
  }) async {
    try {
      await _service.orderDesign(
        designId,
        {"product_detail_id": productDetailId, "quantity": quantity},
      );
      return Right(unit);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, List<HelmetDesign>>> getMyDesigns() async {
    try {
      final response = await _service.getMyDesigns();
      return Right(response.data.map(HelmetDesignMapper.fromModel).toList());
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
