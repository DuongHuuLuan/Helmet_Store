import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_read_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/services/chat_service.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

class ChatRemoteDataSource {
  final ChatService _service;

  ChatRemoteDataSource(this._service);

  Future<Either<Failure, List<ChatConversation>>> getConversations() async {
    try {
      final response = await _service.getConversations();
      final list = response.data.map((m) => ChatConversation.fromJson(m.toJson())).toList();
      return Right(list);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, ChatConversation>> createOrGetConversation({int? userId, int? adminId}) async {
    try {
      final response = await _service.createOrGetConversation({
        "user_id": userId,
        "admin_id": adminId,
      });
      return Right(ChatConversation.fromJson(response.data.toJson()));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, ChatMessagePage>> getMessages(
    int conversationId, {
    int? cursor,
    int limit = 20,
  }) async {
    try {
      final response = await _service.getMessages(
        conversationId,
        cursor: cursor,
        limit: limit,
      );
      final page = response.data;
      return Right(ChatMessagePage(
        items: (page.items ?? []).map((m) => ChatMessage.fromJson(m.toJson())).toList(),
        nextCursor: page.nextCursor,
      ));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, ChatMessage>> sendMessage(
    int conversationId, {
    String? content,
    String? clientMsgId,
    List<String> filePaths = const [],
  }) async {
    try {
      final files = filePaths.isNotEmpty
          ? await Future.wait(filePaths.map((p) => MultipartFile.fromFile(p)))
          : null;
      final response = await _service.sendMessage(
        conversationId,
        content: content,
        clientMsgId: clientMsgId,
        files: files,
      );
      return Right(ChatMessage.fromJson(response.data.toJson()));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Unit>> recallMessage(int conversationId, int messageId) async {
    try {
      await _service.recallMessage(conversationId, messageId);
      return Right(unit);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, ChatReadResult>> markConversationRead(
    int conversationId, {
    int? messageId,
  }) async {
    try {
      final response = await _service.markConversationRead(
        conversationId,
        data: messageId != null ? {"message_id": messageId} : null,
      );
      return Right(ChatReadResult.fromJson(response.data.toJson()));
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }

  Future<Either<Failure, Unit>> addToCartAction(
    int conversationId, {
    required int productDetailId,
    int quantity = 1,
  }) async {
    try {
      await _service.addToCartAction(
        conversationId,
        {"product_detail_id": productDetailId, "quantity": quantity},
      );
      return Right(unit);
    } on DioException catch (e) {
      return Left(Failure.fromDio(e));
    }
  }
}
