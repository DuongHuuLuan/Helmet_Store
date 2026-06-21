import 'package:b2205946_duonghuuluan_luanvan/data/models/profile/profile_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'profile_service.g.dart';

@RestApi()
abstract class ProfileService {
  factory ProfileService(Dio dio, {String baseUrl}) = _ProfileService;

  @GET("/profile/me")
  Future<HttpResponse<ProfileModel>> getProfile();

  @PUT("/profile/me")
  Future<HttpResponse<ProfileModel>> updateProfile(@Body() Map<String, dynamic> data);

  @POST("/profile/me/avatar")
  @MultiPart()
  Future<HttpResponse<ProfileModel>> uploadAvatar(@Part() MultipartFile file);

  @POST("/profile/me/change-password")
  Future<HttpResponse<void>> changePassword(@Body() Map<String, dynamic> data);
}
