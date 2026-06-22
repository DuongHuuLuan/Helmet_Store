import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository _repo;
  GetMessagesUseCase(this._repo);
  Future<Either<Failure, ChatMessagePage>> call(int conversationId, {int? cursor, int limit = 20}) =>
      _repo.getMessages(conversationId, cursor: cursor, limit: limit);
}
