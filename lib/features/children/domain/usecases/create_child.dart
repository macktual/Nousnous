import '../entities/child.dart';
import '../repositories/child_repository.dart';

class CreateChild {
  const CreateChild(this._repository);

  final ChildRepository _repository;

  Future<int> call(Child child) {
    return _repository.createChild(child);
  }
}

