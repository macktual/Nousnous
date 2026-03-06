import 'package:intl/intl.dart';

import '../../domain/entities/vaccination_entry.dart';
import '../../domain/entities/vaccination_rule.dart';
import '../../domain/repositories/vaccination_repository.dart';
import '../datasources/vaccination_local_datasource.dart';
import '../models/vaccination_rule_model.dart';

class VaccinationRepositoryImpl implements VaccinationRepository {
  VaccinationRepositoryImpl(this._local);

  final VaccinationLocalDatasource _local;

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  /// Filtre par schéma : hexavalent = DTP-Coq-Hib-Hépatite B (INFANRIX HEXA, Hexyon, Vaxelis) ; separate = Hib + Hépatite B séparés.
  static bool _isHexavalentRule(VaccinationRuleModel r) =>
      r.name.contains('DTP-Coq-Hib-Hépatite B');
  static bool _isSeparateHibOrHepBRule(VaccinationRuleModel r) =>
      r.name.startsWith('Hib (') || r.name.startsWith('Hépatite B (');

  @override
  Future<List<VaccinationEntry>> getScheduleForChild(
    int childId,
    DateTime birthDate, {
    String? vaccinationScheme,
  }) async {
    final rules = await _local.getAllRules();
    final status = await _local.getVaccinationStatusForChild(childId);
    final entries = <VaccinationEntry>[];
    for (final rule in rules) {
      if (vaccinationScheme == 'hexavalent' && _isSeparateHibOrHepBRule(rule)) continue;
      if (vaccinationScheme == 'separate' && _isHexavalentRule(rule)) continue;
      final theoretical = _addMonths(birthDate, rule.delayMonths);
      final s = status[rule.id];
      final actualDate = s?.actualDate != null && s!.actualDate!.isNotEmpty
          ? _dateFormat.parse(s.actualDate!)
          : null;
      final justificationDate = s?.justificationDate != null && s!.justificationDate!.isNotEmpty
          ? _dateFormat.parse(s.justificationDate!)
          : null;
      entries.add(VaccinationEntry(
        rule: rule.toEntity(),
        theoreticalDate: theoretical,
        actualDate: actualDate,
        isDone: s?.isDone ?? false,
        justificationSource: s?.justificationSource,
        justificationDate: justificationDate,
        justificationPhotoPath: s?.justificationPhotoPath,
      ));
    }
    // Ordre d'affichage : d'abord les vaccins à réaliser (isDone == false),
    // puis ceux déjà faits, en gardant la chronologie par date théorique.
    entries.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      final cmpDate = a.theoreticalDate.compareTo(b.theoreticalDate);
      if (cmpDate != 0) return cmpDate;
      return a.rule.sortOrder.compareTo(b.rule.sortOrder);
    });
    return entries;
  }

  @override
  Future<void> setVaccinationDone(
    int childId,
    int ruleId, {
    DateTime? actualDate,
  }) async {
    final status = await _local.getVaccinationStatusForChild(childId);
    final current = status[ruleId];
    await _local.upsertVaccination(
      childId,
      ruleId,
      actualDate: actualDate != null ? _dateFormat.format(actualDate) : null,
      isDone: true,
      justificationSource: current?.justificationSource,
      justificationDate: current?.justificationDate,
      justificationPhotoPath: current?.justificationPhotoPath,
    );
  }

  @override
  Future<void> setJustification(
    int childId,
    int ruleId, {
    String? justificationSource,
    DateTime? justificationDate,
    String? justificationPhotoPath,
  }) async {
    await _local.updateJustification(
      childId,
      ruleId,
      justificationSource: justificationSource,
      justificationDate: justificationDate != null ? _dateFormat.format(justificationDate) : null,
      justificationPhotoPath: justificationPhotoPath,
    );
  }

  @override
  Future<void> setVaccinationUndone(int childId, int ruleId) async {
    await _local.deleteVaccination(childId, ruleId);
  }

  @override
  Future<List<VaccinationRule>> getAllRules() async {
    final list = await _local.getAllRules();
    return list.map((r) => r.toEntity()).toList();
  }

  @override
  Future<void> updateRule(VaccinationRule rule) async {
    await _local.updateRule(VaccinationRuleModel.fromEntity(rule));
  }

  @override
  Future<void> insertRule(VaccinationRule rule) async {
    await _local.insertRule(VaccinationRuleModel(
      id: 0,
      name: rule.name,
      delayMonths: rule.delayMonths,
      sortOrder: rule.sortOrder,
      notes: rule.notes,
    ));
  }

  @override
  Future<void> deleteRule(int ruleId) async {
    await _local.deleteRule(ruleId);
  }

  DateTime _addMonths(DateTime from, int months) {
    var y = from.year;
    var m = from.month + months;
    while (m > 12) {
      m -= 12;
      y++;
    }
    while (m < 1) {
      m += 12;
      y--;
    }
    var d = from.day;
    final lastDay = DateTime(y, m + 1, 0).day;
    if (d > lastDay) d = lastDay;
    return DateTime(y, m, d);
  }
}
