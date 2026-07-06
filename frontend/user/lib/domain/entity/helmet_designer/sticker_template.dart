class StickerTemplate {
  final int id;
  final String name;
  final String imageUrl;
  final String category;
  final bool isAiGenerated;
  final bool hasTransparentBackground;

  StickerTemplate({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.isAiGenerated,
    required this.hasTransparentBackground,
  });
}
