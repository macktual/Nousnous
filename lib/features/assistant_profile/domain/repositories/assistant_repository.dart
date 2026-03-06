import '../entities/assistant.dart';

abstract class AssistantRepository {
  Future<Assistant?> getProfile();
  Future<void> saveProfile(Assistant assistant);
}

