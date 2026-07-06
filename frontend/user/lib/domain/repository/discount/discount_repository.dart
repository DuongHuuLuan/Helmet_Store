import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:dartz/dartz.dart';

abstract class DiscountRepository {
  Future<Either<Failure, List<Discount>>> getDiscountsForCart({required List<int> categoryIds});
}
