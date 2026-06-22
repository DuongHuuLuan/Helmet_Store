import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/helmet_designer/helmet_designer_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';

class GetStickerCatalogUseCase {
  final HelmetDesignerRepository _repo;
  GetStickerCatalogUseCase(this._repo);
  Future<Either<Failure, List<StickerTemplate>>> call() => _repo.getStickerCatalog();
}
