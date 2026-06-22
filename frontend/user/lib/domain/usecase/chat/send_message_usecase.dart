import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/chat/chat_repository.dart';

class SendMessageUseCase {
  final ChatRepository _repo;
  SendMessageUseCase(this._repo);
  Future<Either<Failure, ChatMessage>> call(int conversationId, {String? content, String? clientMsgId, List<String> filePaths = const []}) =>
      _repo.sendMessage(conversationId, content: content, clientMsgId: clientMsgId, filePaths: filePaths);
}
