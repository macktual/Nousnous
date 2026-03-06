import '../repositories/child_repository.dart';

class ArchiveChild {
  const ArchiveChild(this._repository);

  final ChildRepository _repository;

  Future<void> call(int id, {DateTime? contractEndDate, String? particularitesFinContrat, String? archiveSignaturePath}) {
    return _repository.archiveChild(id, contractEndDate: contractEndDate, particularitesFinContrat: particularitesFinContrat, archiveSignaturePath: archiveSignaturePath);
  }
}

