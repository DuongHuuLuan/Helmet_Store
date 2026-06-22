class ChatMessageMedia {
  final int id;
  final String path;
  final String mediaType;
  final DateTime? createdAt;

  const ChatMessageMedia({
    required this.id,
    required this.path,
    required this.mediaType,
    required this.createdAt,
  });

  factory ChatMessageMedia.fromJson(Map<String, dynamic> json) {
    return ChatMessageMedia(
      id: _parseInt(json["id"]) ?? 0,
      path: (json["path"] ?? "").toString(),
      mediaType: (json["media_type"] ?? "image").toString(),
      createdAt: _parseDate(json["created_at"]),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
