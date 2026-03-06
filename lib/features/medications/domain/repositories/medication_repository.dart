import '../entities/medication_entry.dart';

abstract class MedicationRepository {
  Future<List<MedicationEntry>> getForChild(int childId);
  Future<MedicationEntry> insert(MedicationEntry entry);
  Future<void> update(MedicationEntry entry);
  Future<void> delete(int id);
  /// Liste globale des noms de médicaments déjà utilisés (sans doublons).
  Future<List<String>> getMedicationNames();
}
