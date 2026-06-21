import 'package:json_annotation/json_annotation.dart';

part 'chat_message_media_model.g.dart';

@JsonSerializable()
class ChatMessageMediaModel {
  final int id;
  final String? path;
  @JsonKey(name: 'media_type')
  final String? mediaType;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  ChatMessageMediaModel({
    required this.id,
    this.path,
    this.mediaType,
    this.createdAt,
  });

  factory ChatMessageMediaModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageMediaModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageMediaModelToJson(this);
}
