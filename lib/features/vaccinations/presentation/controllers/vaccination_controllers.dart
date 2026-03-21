import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database_provider.dart';
import '../../data/datasources/vaccination_local_datasource.dart';
import '../../data/repositories/vaccination_repository_impl.dart';
import '../../domain/entities/vaccination_entry.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../../domain/usecases/delete_vaccination_rule.dart';
import '../../domain/usecases/get_vaccination_rules.dart';
import '../../domain/usecases/get_vaccination_schedule.dart';
import '../../domain/usecases/save_vaccination_rule.dart';
import '../../domain/usecases/update_vaccination_status.dart';

final vaccinationLocalDatasourceProvider = Provider<VaccinationLocalDatasource>((ref) {
  return VaccinationLocalDatasource(ref.watch(appDatabaseProvider));
});

final vaccinationRepositoryProvider = Provider<VaccinationRepository>((ref) {
  return VaccinationRepositoryImpl(ref.watch(vaccinationLocalDatasourceProvider));
});

final getVaccinationScheduleProvider = Provider<GetVaccinationSchedule>((ref) {
  return GetVaccinationSchedule(ref.watch(vaccinationRepositoryProvider));
});

final updateVaccinationStatusProvider = Provider<UpdateVaccinationStatus>((ref) {
  return UpdateVaccinationStatus(ref.watch(vaccinationRepositoryProvider));
});

final getVaccinationRulesProvider = Provider<GetVaccinationRules>((ref) {
  return GetVaccinationRules(ref.watch(vaccinationRepositoryProvider));
});

final saveVaccinationRuleProvider = Provider<SaveVaccinationRule>((ref) {
  return SaveVaccinationRule(ref.watch(vaccinationRepositoryProvider));
});

final deleteVaccinationRuleProvider = Provider<DeleteVaccinationRule>((ref) {
  return DeleteVaccinationRule(ref.watch(vaccinationRepositoryProvider));
});

/// Calendrier de vaccinations pour un enfant. (childId, birthDate, vaccinationScheme) -> liste.
final vaccinationScheduleProvider = FutureProvider.family<List<VaccinationEntry>, ({int childId, DateTime birthDate, String? vaccinationScheme})>(
  (ref, key) async {
    if (kIsWeb) return [];
    return ref.read(getVaccinationScheduleProvider).call(
      key.childId,
      key.birthDate,
      vaccinationScheme: key.vaccinationScheme,
    );
  },
);
