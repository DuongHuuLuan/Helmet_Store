import 'package:b2205946_duonghuuluan_luanvan/data/models/chat/chat_conversation_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/chat/chat_message_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/chat/chat_message_page_model.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/models/chat/chat_read_result_model.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'chat_service.g.dart';

@RestApi()
abstract class ChatService {
  factory ChatService(Dio dio, {String baseUrl}) = _ChatService;

  @GET("/chat/conversations")
  Future<HttpResponse<List<ChatConversationModel>>> getConversations();

  @POST("/chat/conversations")
  Future<HttpResponse<ChatConversationModel>> createOrGetConversation(
    @Body() Map<String, dynamic> data,
  );

  @GET("/chat/conversations/{id}/messages")
  Future<HttpResponse<ChatMessagePageModel>> getMessages(
    @Path("id") int conversationId, {
    @Query("cursor") int? cursor,
    @Query("limit") int? limit,
  });

  @POST("/chat/conversations/{id}/messages")
  @MultiPart()
  Future<HttpResponse<ChatMessageModel>> sendMessage(
    @Path("id") int conversationId, {
    @Part() String? content,
    @Part(name: "client_msg_id") String? clientMsgId,
    @Part() List<MultipartFile>? files,
  });

  @POST("/chat/conversations/{cId}/messages/{mId}/recall")
  Future<HttpResponse<void>> recallMessage(
    @Path("cId") int conversationId,
    @Path("mId") int messageId,
  );

  @POST("/chat/conversations/{id}/read")
  Future<HttpResponse<ChatReadResultModel>> markConversationRead(
    @Path("id") int conversationId, {
    @Body() Map<String, dynamic>? data,
  });

  @POST("/chat/conversations/{id}/actions/add-to-cart")
  Future<HttpResponse<void>> addToCartAction(
    @Path("id") int conversationId,
    @Body() Map<String, dynamic> data,
  );
}
