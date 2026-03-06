import '../../domain/entities/assistant.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../datasources/assistant_local_datasource.dart';
import '../models/assistant_model.dart';

class AssistantRepositoryImpl implements AssistantRepository {
  AssistantRepositoryImpl(this._localDatasource);

  final AssistantLocalDatasource _localDatasource;

  @override
  Future<Assistant?> getProfile() {
    return _localDatasource.getProfile();
  }

  @override
  Future<void> saveProfile(Assistant assistant) async {
    final model = AssistantModel(
      id: assistant.id,
      firstName: assistant.firstName,
      lastName: assistant.lastName,
      address: assistant.address,
      approvalNumber: assistant.approvalNumber,
      approvalDate: assistant.approvalDate,
      civility: assistant.civility,
      postalCode: assistant.postalCode,
      city: assistant.city,
      phone: assistant.phone,
      email: assistant.email,
      agreementMaxChildren: assistant.agreementMaxChildren,
      accessCode: assistant.accessCode,
      floor: assistant.floor,
      signaturePath: assistant.signaturePath,
    );
    await _localDatasource.upsertProfile(model);
  }
}

