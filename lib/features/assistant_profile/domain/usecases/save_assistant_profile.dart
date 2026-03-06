import '../entities/assistant.dart';
import '../repositories/assistant_repository.dart';

class SaveAssistantProfile {
  const SaveAssistantProfile(this._repository);

  final AssistantRepository _repository;

  Future<void> call(Assistant assistant) {
    return _repository.saveProfile(assistant);
  }
}

