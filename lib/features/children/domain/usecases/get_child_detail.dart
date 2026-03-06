import '../entities/child.dart';
import '../repositories/child_repository.dart';

class GetChildDetail {
  const GetChildDetail(this._repository);

  final ChildRepository _repository;

  Future<Child?> call(int id) {
    return _repository.getChildById(id);
  }
}

