import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/helmet_designer_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/helmet_designer/helmet_designer_repository.dart';
import 'package:dartz/dartz.dart';

class HelmetDesignerRepositoryImpl implements HelmetDesignerRepository {
  final HelmetDesignerRemoteDataSource _remoteDataSource;

  HelmetDesignerRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<StickerTemplate>>> getStickerCatalog() async {
    return await _remoteDataSource.getStickerCatalog();
  }

  @override
  Future<Either<Failure, StickerTemplate>> generateAiSticker(AiStickerRequest request) async {
    return await _remoteDataSource.generateAiSticker(request);
  }

  @override
  Future<Either<Failure, String>> transcribeAiStickerVoice(String audioPath) async {
    return await _remoteDataSource.transcribeAiStickerVoice(audioPath);
  }

  @override
  Future<Either<Failure, HelmetDesign>> saveDesign(HelmetDesign design) async {
    return await _remoteDataSource.saveDesign(design);
  }

  @override
  Future<Either<Failure, HelmetDesign>> getDesignDetail(int designId) async {
    return await _remoteDataSource.getDesignDetail(designId);
  }

  @override
  Future<Either<Failure, String>> createShareLink(int designId) async {
    return await _remoteDataSource.createShareLink(designId);
  }

  @override
  Future<Either<Failure, Unit>> orderDesign(
    int designId, {
    required int productDetailId,
    int quantity = 1,
  }) async {
    return await _remoteDataSource.orderDesign(
      designId,
      productDetailId: productDetailId,
      quantity: quantity,
    );
  }

  @override
  Future<Either<Failure, List<HelmetDesign>>> getMyDesigns() async {
    return await _remoteDataSource.getMyDesigns();
  }
}
