import 'package:b2205946_duonghuuluan_luanvan/data/models/auth/user_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/user.dart';

class UserMapper {
  static User fromModel(UserModel model) {
    return User(
      id: model.id,
      email: model.email,
      username: model.username,
      role: model.role,
    );
  }

  static Map<String, dynamic> toJson(User entity) {
    return {
      "id": entity.id,
      "email": entity.email,
      "username": entity.username,
      "role": entity.role,
    };
  }
}
