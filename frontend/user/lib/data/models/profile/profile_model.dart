import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  final String? name;
  final String? phone;
  final String? gender;
  final DateTime? birthday;
  final String? avatar;

  ProfileModel({
    required this.id,
    required this.userId,
    this.name,
    this.phone,
    this.gender,
    this.birthday,
    this.avatar,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
