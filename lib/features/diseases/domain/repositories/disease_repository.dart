import '../entities/disease_entry.dart';

abstract class DiseaseRepository {
  Future<List<DiseaseEntry>> getForChild(int childId);
  Future<DiseaseEntry> insert(DiseaseEntry entry);
  Future<void> update(DiseaseEntry entry);
  Future<void> delete(int id);
}
