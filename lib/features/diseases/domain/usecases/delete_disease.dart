import '../repositories/disease_repository.dart';

class DeleteDisease {
  const DeleteDisease(this._repo);

  final DiseaseRepository _repo;

  Future<void> call(int id) {
    return _repo.delete(id);
  }
}
