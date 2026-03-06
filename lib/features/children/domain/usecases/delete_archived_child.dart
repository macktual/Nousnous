import '../repositories/child_repository.dart';

class DeleteArchivedChild {
  const DeleteArchivedChild(this._repository);

  final ChildRepository _repository;

  Future<void> call(int id) {
    return _repository.deleteArchivedChild(id);
  }
}
