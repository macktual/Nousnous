import '../../domain/entities/medication_entry.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_local_datasource.dart';
import '../models/medication_entry_model.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._local);

  final MedicationLocalDatasource _local;

  @override
  Future<List<MedicationEntry>> getForChild(int childId) async {
    final list = await _local.getForChild(childId);
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<MedicationEntry> insert(MedicationEntry entry) async {
    final model = MedicationEntryModel.fromEntity(entry);
    final inserted = await _local.insert(model);
    return inserted.toEntity();
  }

  @override
  Future<void> update(MedicationEntry entry) async {
    final model = MedicationEntryModel.fromEntity(entry);
    await _local.update(model);
  }

  @override
  Future<void> delete(int id) async {
    await _local.delete(id);
  }

  @override
  Future<List<String>> getMedicationNames() {
    return _local.getDistinctMedicationNames();
  }
}
