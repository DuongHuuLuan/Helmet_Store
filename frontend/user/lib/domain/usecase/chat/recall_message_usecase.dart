import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';

class RecallMessageUseCase {
  final ChatRepository _repo;
  RecallMessageUseCase(this._repo);
  Future<Either<Failure, Unit>> call(int conversationId, int messageId) =>
      _repo.recallMessage(conversationId, messageId);
}
