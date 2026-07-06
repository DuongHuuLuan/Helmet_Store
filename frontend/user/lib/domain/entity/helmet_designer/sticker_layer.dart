import 'package:b2205946_duonghuuluan_luanvan/domain/entity/helmet_designer/sticker_crop.dart';

class StickerLayer {
  final int id;
  final int stickerId;
  final String imageUrl;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;
  final String? viewImageKey;
  final int? tintColorValue;
  final StickerCrop crop;

  StickerLayer({
    required this.id,
    required this.stickerId,
    required this.imageUrl,
    required this.x,
    required this.y,
    required this.scale,
    required this.rotation,
    required this.zIndex,
    this.viewImageKey,
    required this.crop,
    this.tintColorValue,
  });

  StickerLayer copyWith({
    int? id,
    int? stickerId,
    String? imageUrl,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
    String? viewImageKey,
    bool clearViewImageKey = false,
    int? tintColorValue,
    bool clearTintColor = false,
    StickerCrop? crop,
  }) {
    return StickerLayer(
      id: id ?? this.id,
      stickerId: stickerId ?? this.stickerId,
      imageUrl: imageUrl ?? this.imageUrl,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      viewImageKey: clearViewImageKey
          ? null
          : (viewImageKey ?? this.viewImageKey),
      tintColorValue: clearTintColor
          ? null
          : (tintColorValue ?? this.tintColorValue),
      crop: crop ?? this.crop,
    );
  }
}
