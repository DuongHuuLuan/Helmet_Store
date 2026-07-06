import 'package:b2205946_duonghuuluan_luanvan/domain/repository/auth/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository _repo;
  LogoutUseCase(this._repo);
  Future<void> call() => _repo.logout();
}
