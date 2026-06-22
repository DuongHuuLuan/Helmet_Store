import 'package:b2205946_duonghuuluan_luanvan/data/models/category/category_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/category/category_page_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'category_service.g.dart';

@RestApi()
abstract class CategoryService {
  factory CategoryService(Dio dio, {String baseUrl}) = _CategoryService;

  @GET("/categories")
  Future<HttpResponse<CategoryPageModel>> getAll({
    @Query("page") int? page,
    @Query("per_page") int? perPage,
  });

  @GET("/categories/{id}")
  Future<HttpResponse<CategoryModel>> getById(@Path("id") int id);

  @GET("/categories/{id}/products")
  Future<HttpResponse<List<CategoryModel>>> getAllProudctByCategoryId(
    @Path("id") int categoryId,
  );
}
