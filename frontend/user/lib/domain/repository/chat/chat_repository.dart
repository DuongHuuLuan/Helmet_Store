import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_read_result.dart';
import 'package:dartz/dartz.dart';

abstract class ChatRepository {
  Future<Either<Failure, List<ChatConversation>>> getConversations();

  Future<Either<Failure, ChatConversation>> createOrGetConversation({int? userId, int? adminId});

  Future<Either<Failure, ChatMessagePage>> getMessages(
    int conversationId, {
    int? cursor,
    int limit = 20,
  });

  Future<Either<Failure, ChatMessage>> sendMessage(
    int conversationId, {
    String? content,
    String? clientMsgId,
    List<String> filePaths = const [],
  });

  Future<Either<Failure, Unit>> recallMessage(int conversationId, int messageId);

  Future<Either<Failure, ChatReadResult>> markConversationRead(
    int conversationId, {
    int? messageId,
  });

  Future<Either<Failure, Unit>> addToCartAction(
    int conversationId, {
    required int productDetailId,
    int quantity = 1,
  });
}
