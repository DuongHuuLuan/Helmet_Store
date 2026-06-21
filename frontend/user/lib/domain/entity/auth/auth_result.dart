import 'package:b2205946_duonghuuluan_luanvan/domain/entity/auth/user.dart';

class AuthResult {
  final User user;
  final String accessToken;

  AuthResult({required this.user, required this.accessToken});
}
