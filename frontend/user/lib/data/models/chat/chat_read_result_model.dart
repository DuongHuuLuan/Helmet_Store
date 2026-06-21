import 'package:json_annotation/json_annotation.dart';

part 'chat_read_result_model.g.dart';

@JsonSerializable()
class ChatReadResultModel {
  @JsonKey(name: 'conversation_id')
  final int conversationId;
  @JsonKey(name: 'last_read_message_id')
  final int? lastReadMessageId;
  @JsonKey(name: 'unread_count')
  final int? unreadCount;
  final bool? changed;

  ChatReadResultModel({
    required this.conversationId,
    this.lastReadMessageId,
    this.unreadCount,
    this.changed,
  });

  factory ChatReadResultModel.fromJson(Map<String, dynamic> json) =>
      _$ChatReadResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatReadResultModelToJson(this);
}
