import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_payload.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_media.dart';

class ChatMessage {
  final int id;
  final int conversationId;
  final int userId;
  final String type;
  final String? clientMsgId;
  final String? senderRole;
  final String? content;
  final ChatMessagePayload? payload;
  final DateTime? createdAt;
  final List<ChatMessageMedia> mediaItems;
  final bool isRecalled;
  final DateTime? recalledAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.type,
    required this.clientMsgId,
    required this.senderRole,
    required this.content,
    required this.payload,
    required this.createdAt,
    required this.mediaItems,
    required this.isRecalled,
    required this.recalledAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final media = json["media_items"];
    final payload = json["payload"];
    return ChatMessage(
      id: _parseInt(json["id"]) ?? 0,
      conversationId: _parseInt(json["conversation_id"]) ?? 0,
      userId: _parseInt(json["user_id"]) ?? 0,
      type: (json["type"] ?? "text").toString(),
      clientMsgId: json["client_msg_id"]?.toString(),
      senderRole: json["sender_role"]?.toString(),
      content: json["content"]?.toString(),
      payload: payload is Map
          ? ChatMessagePayload.fromJson(Map<String, dynamic>.from(payload))
          : null,
      createdAt: _parseDate(json["created_at"]),
      mediaItems: media is List
          ? media
                .whereType<Map>()
                .map(
                  (item) => ChatMessageMedia.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      isRecalled: json["is_recalled"] == true,
      recalledAt: _parseDate(json["recalled_at"]),
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
