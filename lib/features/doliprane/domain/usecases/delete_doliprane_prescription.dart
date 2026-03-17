import '../repositories/doliprane_repository.dart';

class DeleteDolipranePrescription {
  const DeleteDolipranePrescription(this._repo);

  final DolipraneRepository _repo;

  Future<void> call(int id) {
    return _repo.delete(id);
  }
}
