import '../entities/assistant.dart';
import '../repositories/assistant_repository.dart';

class GetAssistantProfile {
  const GetAssistantProfile(this._repository);

  final AssistantRepository _repository;

  Future<Assistant?> call() {
    return _repository.getProfile();
  }
}

