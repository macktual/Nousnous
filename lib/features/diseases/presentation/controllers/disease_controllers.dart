import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../data/datasources/disease_local_datasource.dart';
import '../../data/repositories/disease_repository_impl.dart';
import '../../domain/entities/disease_entry.dart';
import '../../domain/repositories/disease_repository.dart';
import '../../domain/usecases/delete_disease.dart';
import '../../domain/usecases/get_diseases_for_child.dart';
import '../../domain/usecases/save_disease.dart';

final diseaseDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final diseaseLocalDatasourceProvider = Provider<DiseaseLocalDatasource>((ref) {
  return DiseaseLocalDatasource(ref.watch(diseaseDatabaseProvider));
});

final diseaseRepositoryProvider = Provider<DiseaseRepository>((ref) {
  return DiseaseRepositoryImpl(ref.watch(diseaseLocalDatasourceProvider));
});

final getDiseasesForChildProvider = Provider<GetDiseasesForChild>((ref) {
  return GetDiseasesForChild(ref.watch(diseaseRepositoryProvider));
});

final saveDiseaseProvider = Provider<SaveDisease>((ref) {
  return SaveDisease(ref.watch(diseaseRepositoryProvider));
});

final deleteDiseaseProvider = Provider<DeleteDisease>((ref) {
  return DeleteDisease(ref.watch(diseaseRepositoryProvider));
});

/// Liste des maladies pour un enfant. Sur Web retourne [].
final diseasesListProvider =
    FutureProvider.family<List<DiseaseEntry>, int>((ref, childId) async {
  if (kIsWeb) return [];
  return ref.read(getDiseasesForChildProvider).call(childId);
});
