import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database_provider.dart';
import '../../data/datasources/medication_local_datasource.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/entities/medication_entry.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/usecases/delete_medication.dart';
import '../../domain/usecases/get_medications_for_child.dart';
import '../../domain/usecases/get_medication_names.dart';
import '../../domain/usecases/save_medication.dart';

final medicationLocalDatasourceProvider = Provider<MedicationLocalDatasource>((ref) {
  return MedicationLocalDatasource(ref.watch(appDatabaseProvider));
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(ref.watch(medicationLocalDatasourceProvider));
});

final getMedicationsForChildProvider = Provider<GetMedicationsForChild>((ref) {
  return GetMedicationsForChild(ref.watch(medicationRepositoryProvider));
});

final saveMedicationProvider = Provider<SaveMedication>((ref) {
  return SaveMedication(ref.watch(medicationRepositoryProvider));
});

final deleteMedicationProvider = Provider<DeleteMedication>((ref) {
  return DeleteMedication(ref.watch(medicationRepositoryProvider));
});

/// Liste des médicaments pour un enfant. Sur Web retourne [].
final medicationsListProvider =
    FutureProvider.family<List<MedicationEntry>, int>((ref, childId) async {
  if (kIsWeb) return [];
  return ref.read(getMedicationsForChildProvider).call(childId);
});

/// Liste globale des noms de médicaments déjà utilisés (pour suggestions du formulaire).
final medicationNamesProvider = FutureProvider<List<String>>((ref) async {
  if (kIsWeb) return [];
  final usecase = GetMedicationNames(ref.watch(medicationRepositoryProvider));
  // On peut mettre en cache, Riverpod s'en charge (provider simple).
  return usecase();
});
