import 'package:b2205946_duonghuuluan_luanvan/data/models/auth/login_response.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/auth/user_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_service.g.dart';

@RestApi()
abstract class AuthService {
  factory AuthService(Dio dio, {String baseUrl}) = _AuthService;

  @POST("/auth/login/user")
  @FormUrlEncoded()
  Future<HttpResponse<LoginResponse>> login(
    @Field("username") String email,
    @Field("password") String password,
  );

  @POST("/auth/register")
  Future<HttpResponse<void>> register(@Body() Map<String, dynamic> data);

  @GET("/auth/me")
  Future<HttpResponse<UserModel>> getMe();
}
