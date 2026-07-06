import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';

class AddToCartActionUseCase {
  final ChatRepository _repo;
  AddToCartActionUseCase(this._repo);
  Future<Either<Failure, Unit>> call(int conversationId, {required int productDetailId, int quantity = 1}) =>
      _repo.addToCartAction(conversationId, productDetailId: productDetailId, quantity: quantity);
}
