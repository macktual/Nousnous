import '../../domain/entities/doliprane_prescription.dart';
import '../../domain/repositories/doliprane_repository.dart';
import '../datasources/doliprane_local_datasource.dart';
import '../models/doliprane_prescription_model.dart';

class DolipraneRepositoryImpl implements DolipraneRepository {
  DolipraneRepositoryImpl(this._local);

  final DolipraneLocalDatasource _local;

  @override
  Future<List<DolipranePrescription>> getForChild(int childId) async {
    final list = await _local.getForChild(childId);
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<DolipranePrescription> insert(DolipranePrescription prescription) async {
    final model = DolipranePrescriptionModel.fromEntity(prescription);
    final inserted = await _local.insert(model);
    return inserted.toEntity();
  }

  @override
  Future<void> update(DolipranePrescription prescription) async {
    final model = DolipranePrescriptionModel.fromEntity(prescription);
    await _local.update(model);
  }

  @override
  Future<void> delete(int id) async {
    await _local.delete(id);
  }
}
