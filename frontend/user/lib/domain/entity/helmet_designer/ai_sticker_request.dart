class AiStickerRequest {
  final String prompt;
  final String? style;
  final String? dominantColor;
  final bool removeBackground;

  AiStickerRequest({
    required this.prompt,
    this.style,
    this.dominantColor,
    this.removeBackground = true,
  });
}
