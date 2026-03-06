import '../entities/child.dart';
import '../repositories/child_repository.dart';

class GetArchivedChildren {
  const GetArchivedChildren(this._repository);

  final ChildRepository _repository;

  Future<List<Child>> call() {
    return _repository.getArchivedChildren();
  }
}

