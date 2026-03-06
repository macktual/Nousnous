import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../models/vaccination_rule_model.dart';

class VaccinationLocalDatasource {
  VaccinationLocalDatasource(this._db);

  final AppDatabase _db;

  Future<Database> get _database async => _db.database;

  Future<List<VaccinationRuleModel>> getAllRules() async {
    final db = await _database;
    final rows = await db.query(
      'vaccination_rules',
      // Classement chronologique : d'abord par âge théorique (delay_months),
      // puis par sort_order pour garder un ordre stable entre vaccins du même âge.
      orderBy: 'delay_months ASC, sort_order ASC, id ASC',
    );
    return rows.map(VaccinationRuleModel.fromMap).toList();
  }

  Future<void> insertRule(VaccinationRuleModel rule) async {
    final db = await _database;
    await db.insert('vaccination_rules', rule.toMap());
  }

  Future<void> updateRule(VaccinationRuleModel rule) async {
    final db = await _database;
    await db.update(
      'vaccination_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<void> deleteRule(int ruleId) async {
    final db = await _database;
    await db.delete(
      'vaccination_rules',
      where: 'id = ?',
      whereArgs: [ruleId],
    );
    await db.delete(
      'vaccinations',
      where: 'rule_id = ?',
      whereArgs: [ruleId],
    );
  }

  /// Retourne les lignes (child_id, rule_id, actual_date, is_done, justification*) pour l'enfant.
  Future<Map<int, ({
    String? actualDate,
    bool isDone,
    String? justificationSource,
    String? justificationDate,
    String? justificationPhotoPath,
  })>> getVaccinationStatusForChild(int childId) async {
    final db = await _database;
    final rows = await db.query(
      'vaccinations',
      where: 'child_id = ?',
      whereArgs: [childId],
    );
    final map = <int, ({
      String? actualDate,
      bool isDone,
      String? justificationSource,
      String? justificationDate,
      String? justificationPhotoPath,
    })>{};
    for (final r in rows) {
      final ruleId = r['rule_id'] as int?;
      if (ruleId != null) {
        map[ruleId] = (
          actualDate: r['actual_date'] as String?,
          isDone: (r['is_done'] as int?) == 1,
          justificationSource: r['justification_source'] as String?,
          justificationDate: r['justification_date'] as String?,
          justificationPhotoPath: r['justification_photo_path'] as String?,
        );
      }
    }
    return map;
  }

  Future<void> upsertVaccination(
    int childId,
    int ruleId, {
    String? actualDate,
    required bool isDone,
    String? justificationSource,
    String? justificationDate,
    String? justificationPhotoPath,
  }) async {
    final db = await _database;
    await db.delete(
      'vaccinations',
      where: 'child_id = ? AND rule_id = ?',
      whereArgs: [childId, ruleId],
    );
    await db.insert(
      'vaccinations',
      {
        'child_id': childId,
        'rule_id': ruleId,
        'actual_date': actualDate,
        'is_done': isDone ? 1 : 0,
        'justification_source': justificationSource,
        'justification_date': justificationDate,
        'justification_photo_path': justificationPhotoPath,
      },
    );
  }

  /// Met à jour uniquement les champs justificatif pour une vaccination existante.
  Future<void> updateJustification(
    int childId,
    int ruleId, {
    String? justificationSource,
    String? justificationDate,
    String? justificationPhotoPath,
  }) async {
    final db = await _database;
    await db.update(
      'vaccinations',
      {
        'justification_source': justificationSource,
        'justification_date': justificationDate,
        'justification_photo_path': justificationPhotoPath,
      },
      where: 'child_id = ? AND rule_id = ?',
      whereArgs: [childId, ruleId],
    );
  }

  /// Supprime la ligne pour (child_id, rule_id) pour remettre "non fait".
  Future<void> deleteVaccination(int childId, int ruleId) async {
    final db = await _database;
    await db.delete(
      'vaccinations',
      where: 'child_id = ? AND rule_id = ?',
      whereArgs: [childId, ruleId],
    );
  }
}
