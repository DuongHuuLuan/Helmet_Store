import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_layer.dart';

class HelmetDesign {
  final int id;
  final int helmetProductId;
  final int? productDetailId;
  final String helmetName;
  final String helmetBaseImageUrl;
  final List<StickerLayer> stickers;
  final bool isShared;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HelmetDesign({
    required this.id,
    required this.helmetProductId,
    this.productDetailId,
    required this.helmetName,
    required this.helmetBaseImageUrl,
    required this.stickers,
    required this.isShared,
    this.createdAt,
    this.updatedAt,
  });

  HelmetDesign copyWith({
    int? id,
    int? helmetProductId,
    int? productDetailId,
    bool clearProductDetailId = false,
    String? helmetName,
    String? helmetBaseImageUrl,
    List<StickerLayer>? stickers,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HelmetDesign(
      id: id ?? this.id,
      helmetProductId: helmetProductId ?? this.helmetProductId,
      productDetailId: clearProductDetailId
          ? null
          : productDetailId ?? this.productDetailId,
      helmetName: helmetName ?? this.helmetName,
      helmetBaseImageUrl: helmetBaseImageUrl ?? this.helmetBaseImageUrl,
      stickers: stickers ?? this.stickers,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
