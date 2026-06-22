import 'package:b2205946_duonghuuluan_luanvan/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/repository/helmet_designer/helmet_designer_repository.dart';

class TranscribeAiStickerVoiceUseCase {
  final HelmetDesignerRepository _repo;
  TranscribeAiStickerVoiceUseCase(this._repo);
  Future<Either<Failure, String>> call(String audioPath) => _repo.transcribeAiStickerVoice(audioPath);
}
