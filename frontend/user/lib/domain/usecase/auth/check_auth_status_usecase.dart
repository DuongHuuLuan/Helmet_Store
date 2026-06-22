import 'package:b2205946_duonghuuluan_luanvan/domain/repository/auth/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository _repo;
  CheckAuthStatusUseCase(this._repo);
  Future<bool> call() => _repo.checkAuthStatus();
}
