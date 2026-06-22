import 'package:json_annotation/json_annotation.dart';
import 'chat_message_media_model.dart';

part 'chat_message_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatMessageModel {
  final int id;
  @JsonKey(name: 'conversation_id')
  final int conversationId;
  @JsonKey(name: 'user_id')
  final int userId;
  final String? type;
  @JsonKey(name: 'client_msg_id')
  final String? clientMsgId;
  @JsonKey(name: 'sender_role')
  final String? senderRole;
  final String? content;
  final Map<String, dynamic>? payload;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'media_items')
  final List<ChatMessageMediaModel>? mediaItems;
  @JsonKey(name: 'is_recalled')
  final bool? isRecalled;
  @JsonKey(name: 'recalled_at')
  final DateTime? recalledAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.type,
    this.clientMsgId,
    this.senderRole,
    this.content,
    this.payload,
    this.createdAt,
    this.mediaItems,
    this.isRecalled,
    this.recalledAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);
}
