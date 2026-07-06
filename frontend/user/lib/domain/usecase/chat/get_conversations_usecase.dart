import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';

class GetConversationsUseCase {
  final ChatRepository _repo;
  GetConversationsUseCase(this._repo);
  Future<Either<Failure, List<ChatConversation>>> call() => _repo.getConversations();
}
