import '../entities/child.dart';
import '../repositories/child_repository.dart';

class UpdateChild {
  const UpdateChild(this._repository);

  final ChildRepository _repository;

  Future<void> call(Child child) {
    return _repository.updateChild(child);
  }
}

