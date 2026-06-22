class StickerCrop {
  final double left;
  final double top;
  final double right;
  final double bottom;

  StickerCrop({
    this.left = 0,
    this.top = 0,
    this.right = 1,
    this.bottom = 1,
  });

  StickerCrop copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    return StickerCrop(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
    );
  }
}
