import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/discount_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/discount/discount.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/discount/discount_repository.dart';
import 'package:dartz/dartz.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  final DiscountRemoteDataSource _remoteDataSource;

  DiscountRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<Discount>>> getDiscountsForCart({
    required List<int> categoryIds,
  }) async {
    return await _remoteDataSource.getDiscountsForCart(categoryIds: categoryIds);
  }
}
