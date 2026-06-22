import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/discount/discount_repository.dart';

class GetDiscountsForCartUseCase {
  final DiscountRepository _repo;
  GetDiscountsForCartUseCase(this._repo);
  Future<Either<Failure, List<Discount>>> call({required List<int> categoryIds}) =>
      _repo.getDiscountsForCart(categoryIds: categoryIds);
}
