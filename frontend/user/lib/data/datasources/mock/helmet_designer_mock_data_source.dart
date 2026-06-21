import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/ai_sticker_request.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/helmet_design.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_crop.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_layer.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_template.dart';
import 'package:dartz/dartz.dart';

class HelmetDesignerMockDataSource {
  static final List<StickerTemplate> _stickerCatalog = [
    StickerTemplate(
      id: 1,
      name: "Royal Crest",
      imageUrl: "assets/images/logo_royalStore2.png",
      category: "Logo",
      isAiGenerated: false,
      hasTransparentBackground: true,
    ),
    StickerTemplate(
      id: 2,
      name: "Royal Mark",
      imageUrl: "assets/images/logo_royalStore.png",
      category: "Logo",
      isAiGenerated: false,
      hasTransparentBackground: true,
    ),
    StickerTemplate(
      id: 3,
      name: "Street Burst",
      imageUrl: "assets/images/banner1.webp",
      category: "Street",
      isAiGenerated: false,
      hasTransparentBackground: false,
    ),
    StickerTemplate(
      id: 4,
      name: "Speed Wave",
      imageUrl: "assets/images/banner2.webp",
      category: "Sport",
      isAiGenerated: false,
      hasTransparentBackground: false,
    ),
    StickerTemplate(
      id: 5,
      name: "Urban Flame",
      imageUrl: "assets/images/banner3.webp",
      category: "Graphic",
      isAiGenerated: false,
      hasTransparentBackground: false,
    ),
    StickerTemplate(
      id: 6,
      name: "Sunset Stripe",
      imageUrl: "assets/images/banner4.webp",
      category: "Graphic",
      isAiGenerated: false,
      hasTransparentBackground: false,
    ),
  ];

  static final Map<int, HelmetDesign> _designs = {
    1001: HelmetDesign(
      id: 1001,
      helmetProductId: 101,
      productDetailId: 10001,
      helmetName: "Royal Street Helmet",
      helmetBaseImageUrl: "assets/images/logo.webp",
      stickers: [
        StickerLayer(
          id: 1,
          stickerId: 1,
          imageUrl: "assets/images/logo_royalStore2.png",
          x: 0.38,
          y: 0.32,
          scale: 0.9,
          rotation: 0.0,
          zIndex: 0,
          crop: StickerCrop(left: 0, top: 0, right: 1, bottom: 1),
        ),
        StickerLayer(
          id: 2,
          stickerId: 4,
          imageUrl: "assets/images/banner2.webp",
          x: 0.57,
          y: 0.56,
          scale: 0.65,
          rotation: -0.18,
          zIndex: 1,
          crop: StickerCrop(left: 0.1, top: 0.1, right: 0.9, bottom: 0.9),
          tintColorValue: 4294924066,
        ),
      ],
      isShared: false,
      createdAt: DateTime(2026, 3, 12),
      updatedAt: DateTime(2026, 3, 12),
    ),
  };

  static int _nextStickerId = 100;
  static int _nextDesignId = 2000;

  Either<Failure, List<StickerTemplate>> getStickerCatalog() => Right(List.from(_stickerCatalog));

  Either<Failure, StickerTemplate> generateAiSticker(AiStickerRequest request) {
    final images = _stickerCatalog.map((s) => s.imageUrl).toList();
    final imageUrl = images[request.prompt.length % images.length];
    final sticker = StickerTemplate(
      id: _nextStickerId++,
      name: request.prompt.trim().isEmpty ? "AI Sticker" : request.prompt.trim(),
      imageUrl: imageUrl,
      category: request.style?.trim().isNotEmpty == true ? request.style!.trim() : "AI",
      isAiGenerated: true,
      hasTransparentBackground: request.removeBackground,
    );
    _stickerCatalog.insert(0, sticker);
    return Right(sticker);
  }

  Either<Failure, String> transcribeAiStickerVoice(String audioPath) {
    final name = audioPath.split(RegExp(r"[\\/]")).last.toLowerCase();
    if (name.contains("fire")) {
      return Right("rồng lửa phong cách thể thao");
    }
    return Right("sticker rồng lửa phong cách thể thao");
  }

  Either<Failure, HelmetDesign> saveDesign(HelmetDesign design) {
    final now = DateTime.now();
    final saved = HelmetDesign(
      id: design.id > 0 ? design.id : _nextDesignId++,
      helmetProductId: design.helmetProductId,
      productDetailId: design.productDetailId,
      helmetName: design.helmetName,
      helmetBaseImageUrl: design.helmetBaseImageUrl,
      stickers: design.stickers,
      isShared: design.isShared,
      createdAt: design.createdAt ?? now,
      updatedAt: now,
    );
    _designs[saved.id] = saved;
    return Right(saved);
  }

  Either<Failure, HelmetDesign> getDesignDetail(int designId) {
    final design = _designs[designId] ?? _designs.values.first;
    return Right(design);
  }

  Either<Failure, String> createShareLink(int designId) {
    return Right("https://royalstore.local/designs/$designId");
  }

  Either<Failure, Unit> orderDesign(int designId, {required int productDetailId, int quantity = 1}) {
    if (!_designs.containsKey(designId)) {
      return Left(Failure(message: "Design $designId not found"));
    }
    if (productDetailId <= 0) {
      return Left(Failure(message: "Product detail is required"));
    }
    if (quantity <= 0) {
      return Left(Failure(message: "Quantity must be greater than 0"));
    }
    return Right(unit);
  }
}
