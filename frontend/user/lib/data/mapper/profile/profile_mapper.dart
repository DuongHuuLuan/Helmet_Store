import 'package:b2205946_duonghuuluan_luanvan/data/models/profile/profile_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/profile/profile.dart';

class ProfileMapper {
  static Profile fromModel(ProfileModel model) {
    return Profile(
      id: model.id,
      userId: model.userId,
      name: model.name,
      phone: model.phone,
      gender: model.gender,
      birthday: model.birthday,
      avatar: model.avatar,
    );
  }
}
