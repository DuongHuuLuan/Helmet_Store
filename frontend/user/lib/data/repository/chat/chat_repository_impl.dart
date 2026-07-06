import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/data/datasources/remote/chat_remote_data_source.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_read_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';
import 'package:dartz/dartz.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, List<ChatConversation>>> getConversations() async {
    return await _remoteDataSource.getConversations();
  }

  @override
  Future<Either<Failure, ChatConversation>> createOrGetConversation({int? userId, int? adminId}) async {
    return await _remoteDataSource.createOrGetConversation(userId: userId, adminId: adminId);
  }

  @override
  Future<Either<Failure, ChatMessagePage>> getMessages(
    int conversationId, {
    int? cursor,
    int limit = 20,
  }) async {
    return await _remoteDataSource.getMessages(conversationId, cursor: cursor, limit: limit);
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(
    int conversationId, {
    String? content,
    String? clientMsgId,
    List<String> filePaths = const [],
  }) async {
    return await _remoteDataSource.sendMessage(
      conversationId,
      content: content,
      clientMsgId: clientMsgId,
      filePaths: filePaths,
    );
  }

  @override
  Future<Either<Failure, Unit>> recallMessage(int conversationId, int messageId) async {
    return await _remoteDataSource.recallMessage(conversationId, messageId);
  }

  @override
  Future<Either<Failure, ChatReadResult>> markConversationRead(
    int conversationId, {
    int? messageId,
  }) async {
    return await _remoteDataSource.markConversationRead(conversationId, messageId: messageId);
  }

  @override
  Future<Either<Failure, Unit>> addToCartAction(
    int conversationId, {
    required int productDetailId,
    int quantity = 1,
  }) async {
    return await _remoteDataSource.addToCartAction(
      conversationId,
      productDetailId: productDetailId,
      quantity: quantity,
    );
  }
}
