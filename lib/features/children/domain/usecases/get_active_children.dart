import '../entities/child.dart';
import '../repositories/child_repository.dart';

class GetActiveChildren {
  const GetActiveChildren(this._repository);

  final ChildRepository _repository;

  Future<List<Child>> call() {
    return _repository.getActiveChildren();
  }
}

