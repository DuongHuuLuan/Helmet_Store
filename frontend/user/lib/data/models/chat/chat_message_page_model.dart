import 'package:json_annotation/json_annotation.dart';
import 'chat_message_model.dart';

part 'chat_message_page_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatMessagePageModel {
  final List<ChatMessageModel>? items;
  @JsonKey(name: 'next_cursor')
  final int? nextCursor;

  ChatMessagePageModel({this.items, this.nextCursor});

  factory ChatMessagePageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessagePageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessagePageModelToJson(this);
}
