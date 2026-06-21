import 'package:b2205946_duonghuuluan_luanvan/data/models/evaluate/evaluate_item_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/evaluate/evaluate_page_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/evaluate/product_evaluate_page_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'evaluate_service.g.dart';

@RestApi()
abstract class EvaluateService {
  factory EvaluateService(Dio dio, {String baseUrl}) = _EvaluateService;

  @GET("/evaluates/my")
  Future<HttpResponse<EvaluatePageModel>> getMyEvaluates({
    @Query("page") int? page,
    @Query("per_page") int? perPage,
  });

  @GET("/evaluates/product/{id}")
  Future<HttpResponse<ProductEvaluatePageModel>> getProductEvaluates(
    @Path("id") int productId, {
    @Query("page") int? page,
    @Query("per_page") int? perPage,
  });

  @GET("/evaluates/{id}")
  Future<HttpResponse<EvaluateItemModel>> getEvaluateDetail(@Path("id") int evaluateId);

  @GET("/evaluates/order/{id}")
  Future<HttpResponse<EvaluateItemModel>> getEvaluateByOrder(@Path("id") int orderId);

  @POST("/evaluates/{id}")
  @MultiPart()
  Future<HttpResponse<EvaluateItemModel>> createEvaluate(
    @Path("id") int orderId,
    @Part() int rate, {
    @Part() String? content,
    @Part() List<MultipartFile>? images,
  });
}
