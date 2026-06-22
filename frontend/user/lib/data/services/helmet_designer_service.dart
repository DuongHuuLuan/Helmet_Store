import 'package:b2205946_duonghuuluan_luanvan/data/models/helmet_designer/sticker_template_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/helmet_designer/helmet_design_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'helmet_designer_service.g.dart';

@RestApi()
abstract class HelmetDesignerService {
  factory HelmetDesignerService(Dio dio, {String baseUrl}) = _HelmetDesignerService;

  @GET("/stickers/")
  Future<HttpResponse<List<StickerTemplateModel>>> getStickerCatalog();

  @POST("/stickers/generate")
  Future<HttpResponse<StickerTemplateModel>> generateAiSticker(
    @Body() Map<String, dynamic> body,
  );

  @POST("/stickers/transcribe-voice")
  @MultiPart()
  Future<HttpResponse<dynamic>> transcribeAiStickerVoice(
    @Part() MultipartFile audio,
  );

  @POST("/designs/")
  Future<HttpResponse<HelmetDesignModel>> createDesign(@Body() Map<String, dynamic> body);

  @PUT("/designs/{id}")
  Future<HttpResponse<HelmetDesignModel>> updateDesign(
    @Path("id") int designId,
    @Body() Map<String, dynamic> body,
  );

  @GET("/designs/{id}")
  Future<HttpResponse<HelmetDesignModel>> getDesignDetail(@Path("id") int designId);

  @POST("/designs/{id}/share")
  Future<HttpResponse<dynamic>> createShareLink(@Path("id") int designId);

  @POST("/designs/{id}/order")
  Future<HttpResponse<void>> orderDesign(
    @Path("id") int designId,
    @Body() Map<String, dynamic> data,
  );

  @GET("/designs/my-designs")
  Future<HttpResponse<List<HelmetDesignModel>>> getMyDesigns();
}
