import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_read_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';

class MarkConversationReadUseCase {
  final ChatRepository _repo;
  MarkConversationReadUseCase(this._repo);
  Future<Either<Failure, ChatReadResult>> call(int conversationId, {int? messageId}) =>
      _repo.markConversationRead(conversationId, messageId: messageId);
}
