import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database_provider.dart';
import '../../data/datasources/doliprane_local_datasource.dart';
import '../../data/repositories/doliprane_repository_impl.dart';
import '../../domain/entities/doliprane_prescription.dart';
import '../../domain/repositories/doliprane_repository.dart';
import '../../domain/usecases/delete_doliprane_prescription.dart';
import '../../domain/usecases/get_doliprane_for_child.dart';
import '../../domain/usecases/save_doliprane_prescription.dart';

final dolipraneLocalDatasourceProvider = Provider<DolipraneLocalDatasource>((ref) {
  return DolipraneLocalDatasource(ref.watch(appDatabaseProvider));
});

final dolipraneRepositoryProvider = Provider<DolipraneRepository>((ref) {
  return DolipraneRepositoryImpl(ref.watch(dolipraneLocalDatasourceProvider));
});

final getDolipraneForChildProvider = Provider<GetDolipraneForChild>((ref) {
  return GetDolipraneForChild(ref.watch(dolipraneRepositoryProvider));
});

final saveDolipranePrescriptionProvider = Provider<SaveDolipranePrescription>((ref) {
  return SaveDolipranePrescription(ref.watch(dolipraneRepositoryProvider));
});

final deleteDolipranePrescriptionProvider = Provider<DeleteDolipranePrescription>((ref) {
  return DeleteDolipranePrescription(ref.watch(dolipraneRepositoryProvider));
});

/// Liste des ordonnances Doliprane pour un enfant.
final dolipraneListProvider =
    FutureProvider.family<List<DolipranePrescription>, int>((ref, childId) async {
  if (kIsWeb) return [];
  return ref.read(getDolipraneForChildProvider).call(childId);
});
