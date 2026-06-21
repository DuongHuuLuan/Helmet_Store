import 'package:json_annotation/json_annotation.dart';

part 'chat_conversation_model.g.dart';

@JsonSerializable()
class ChatConversationModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'admin_id')
  final int adminId;
  final String? status;
  @JsonKey(name: 'last_message_id')
  final int? lastMessageId;
  @JsonKey(name: 'last_read_user_message_id')
  final int? lastReadUserMessageId;
  @JsonKey(name: 'last_read_admin_message_id')
  final int? lastReadAdminMessageId;
  @JsonKey(name: 'last_read_message_id')
  final int? lastReadMessageId;
  @JsonKey(name: 'unread_count')
  final int? unreadCount;
  @JsonKey(name: 'last_message_at')
  final DateTime? lastMessageAt;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  ChatConversationModel({
    required this.id,
    required this.userId,
    required this.adminId,
    this.status,
    this.lastMessageId,
    this.lastReadUserMessageId,
    this.lastReadAdminMessageId,
    this.lastReadMessageId,
    this.unreadCount,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatConversationModelToJson(this);
}
