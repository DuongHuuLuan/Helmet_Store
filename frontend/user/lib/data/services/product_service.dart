import 'package:b2205946_duonghuuluan_luanvan/data/models/product/product_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/product/product_page_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'product_service.g.dart';

@RestApi()
abstract class ProductService {
  factory ProductService(Dio dio, {String baseUrl}) = _ProductService;

  @GET("/products")
  Future<HttpResponse<ProductPageModel>> getAllProduct({
    @Query("page") int? page,
    @Query("per_page") int? perPage,
    @Query("q") String? keyword,
  });

  @GET("/products/{id}")
  Future<HttpResponse<ProductModel>> productDetail(@Path("id") int id);

  @GET("/products/category/{id}")
  Future<HttpResponse<ProductPageModel>> getByCategory(
    @Path("id") int categoryId, {
    @Query("page") int? page,
    @Query("per_page") int? perPage,
  });
}
