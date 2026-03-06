import '../../domain/entities/disease_entry.dart';
import '../../domain/repositories/disease_repository.dart';
import '../datasources/disease_local_datasource.dart';
import '../models/disease_entry_model.dart';

class DiseaseRepositoryImpl implements DiseaseRepository {
  DiseaseRepositoryImpl(this._local);

  final DiseaseLocalDatasource _local;

  @override
  Future<List<DiseaseEntry>> getForChild(int childId) async {
    final list = await _local.getForChild(childId);
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<DiseaseEntry> insert(DiseaseEntry entry) async {
    final model = DiseaseEntryModel.fromEntity(entry);
    final inserted = await _local.insert(model);
    return inserted.toEntity();
  }

  @override
  Future<void> update(DiseaseEntry entry) async {
    final model = DiseaseEntryModel.fromEntity(entry);
    await _local.update(model);
  }

  @override
  Future<void> delete(int id) async {
    await _local.delete(id);
  }
}
