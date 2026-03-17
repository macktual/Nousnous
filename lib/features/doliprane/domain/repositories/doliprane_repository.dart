import '../entities/doliprane_prescription.dart';

abstract class DolipraneRepository {
  Future<List<DolipranePrescription>> getForChild(int childId);
  Future<DolipranePrescription> insert(DolipranePrescription prescription);
  Future<void> update(DolipranePrescription prescription);
  Future<void> delete(int id);
}
