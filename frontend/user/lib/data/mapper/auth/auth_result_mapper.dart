import 'package:b2205946_duonghuuluan_luanvan/data/models/auth/login_response.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/mapper/auth/user_mapper.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/auth_result.dart';

class AuthResultMapper {
  static AuthResult fromResponse(LoginResponse response) {
    return AuthResult(
      user: UserMapper.fromModel(response.user),
      accessToken: response.accessToken,
    );
  }
}
