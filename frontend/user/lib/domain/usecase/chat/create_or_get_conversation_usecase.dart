import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';

class CreateOrGetConversationUseCase {
  final ChatRepository _repo;
  CreateOrGetConversationUseCase(this._repo);
  Future<Either<Failure, ChatConversation>> call({int? userId, int? adminId}) =>
      _repo.createOrGetConversation(userId: userId, adminId: adminId);
}
