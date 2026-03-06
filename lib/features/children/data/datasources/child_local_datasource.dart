import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../models/child_model.dart';

class ChildLocalDatasource {
  ChildLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _db async => _appDatabase.database;

  Future<List<ChildModel>> getChildren({required bool archived}) async {
    final db = await _db;
    final rows = await db.query(
      'children',
      where: 'is_archived = ?',
      whereArgs: [archived ? 1 : 0],
      orderBy: 'last_name COLLATE NOCASE, first_name COLLATE NOCASE',
    );
    return rows.map(ChildModel.fromMap).toList();
  }

  Future<ChildModel?> getChild(int id) async {
    final db = await _db;
    final rows = await db.query(
      'children',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ChildModel.fromMap(rows.first);
  }

  Future<List<ParentModel>> getParents(int childId) async {
    final db = await _db;
    final rows = await db.query(
      'parents',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'role',
    );
    return rows.map(ParentModel.fromMap).toList();
  }

  Future<List<WeeklyPatternModel>> getPatterns(int childId) async {
    final db = await _db;
    final rows = await db.query(
      'weekly_patterns',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'CASE WHEN valid_from IS NULL THEN 0 ELSE 1 END, valid_from ASC, id ASC',
    );
    return rows.map(WeeklyPatternModel.fromMap).toList();
  }

  Future<List<ScheduleEntryModel>> getEntriesForPattern(int patternId) async {
    final db = await _db;
    final rows = await db.query(
      'schedules',
      where: 'pattern_id = ?',
      whereArgs: [patternId],
      orderBy: 'weekday',
    );
    return rows.map(ScheduleEntryModel.fromMap).toList();
  }

  /// [entriesPerPatternInOrder] : une liste par pattern, dans le même ordre que [patterns].
  Future<int> insertChild(
    ChildModel child,
    List<ParentModel> parents,
    List<WeeklyPatternModel> patterns,
    List<List<ScheduleEntryModel>> entriesPerPatternInOrder,
  ) async {
    final db = await _db;
    return db.transaction<int>((txn) async {
      final childId = await txn.insert(
        'children',
        child.toMap(),
      );

      for (final parent in parents) {
        await txn.insert(
          'parents',
          parent.copyWith(childId: childId).toMap(),
        );
      }

      for (var i = 0; i < patterns.length; i++) {
        final pattern = patterns[i];
        final patternId = await txn.insert(
          'weekly_patterns',
          pattern.copyWith(childId: childId).toMap(),
        );
        final entries = i < entriesPerPatternInOrder.length
            ? entriesPerPatternInOrder[i]
            : <ScheduleEntryModel>[];
        for (final entry in entries) {
          await txn.insert(
            'schedules',
            entry.copyWith(patternId: patternId).toMap(),
          );
        }
      }

      return childId;
    });
  }

  Future<void> updateChild(
    ChildModel child,
    List<ParentModel> parents,
    List<WeeklyPatternModel> patterns,
    Map<int, List<ScheduleEntryModel>> patternEntries,
  ) async {
    final db = await _db;
    final map = child.toMap();
    map.remove('is_archived'); // ne jamais écraser l'archivage
    await db.transaction<void>((txn) async {
      await txn.update(
        'children',
        map,
        where: 'id = ?',
        whereArgs: [child.id],
      );

      await txn.delete(
        'parents',
        where: 'child_id = ?',
        whereArgs: [child.id],
      );
      for (final parent in parents) {
        await txn.insert(
          'parents',
          parent.copyWith(childId: child.id).toMap(),
        );
      }

      // Ne supprimer que les patterns "courants" (valid_until IS NULL) pour conserver l'historique
      final patternsRows = await txn.query(
        'weekly_patterns',
        columns: ['id'],
        where: 'child_id = ? AND valid_until IS NULL',
        whereArgs: [child.id],
      );
      for (final row in patternsRows) {
        final pid = row['id'] as int;
        await txn.delete(
          'schedules',
          where: 'pattern_id = ?',
          whereArgs: [pid],
        );
      }
      await txn.delete(
        'weekly_patterns',
        where: 'child_id = ? AND valid_until IS NULL',
        whereArgs: [child.id],
      );

      for (final pattern in patterns) {
        final patternId = await txn.insert(
          'weekly_patterns',
          pattern.copyWith(childId: child.id).toMap(),
        );
        final entries = patternEntries[pattern.id] ?? <ScheduleEntryModel>[];
        for (final entry in entries) {
          await txn.insert(
            'schedules',
            entry.copyWith(patternId: patternId).toMap(),
          );
        }
      }
    });
  }

  /// Enregistre un changement d'horaires à compter d'une date : clôture les patterns courants
  /// et insère les nouveaux avec valid_from = [validFromDate].
  Future<void> addScheduleChange(
    int childId,
    DateTime validFromDate,
    List<WeeklyPatternModel> newPatterns,
    List<List<ScheduleEntryModel>> entriesPerPatternInOrder,
  ) async {
    final db = await _db;
    final dateStr = '${validFromDate.year}-${validFromDate.month.toString().padLeft(2, '0')}-${validFromDate.day.toString().padLeft(2, '0')}';
    await db.transaction<void>((txn) async {
      await txn.rawUpdate(
        'UPDATE weekly_patterns SET valid_until = ? WHERE child_id = ? AND valid_until IS NULL',
        [dateStr, childId],
      );
      for (var i = 0; i < newPatterns.length; i++) {
        final pattern = newPatterns[i].copyWith(
          childId: childId,
          validFrom: validFromDate,
          validUntil: null,
        );
        final patternId = await txn.insert(
          'weekly_patterns',
          pattern.toMap(),
        );
        final entries = i < entriesPerPatternInOrder.length
            ? entriesPerPatternInOrder[i]
            : <ScheduleEntryModel>[];
        for (final entry in entries) {
          await txn.insert(
            'schedules',
            entry.copyWith(patternId: patternId).toMap(),
          );
        }
      }
    });
  }

  Future<void> archiveChild(int id, {String? contractEndDate, String? particularitesFinContrat, String? archiveSignaturePath}) async {
    final db = await _db;
    await db.update(
      'children',
      <String, Object?>{
        'is_archived': 1,
        'contract_end_date': contractEndDate,
        'particularites_fin_contrat': particularitesFinContrat,
        'archive_signature_path': archiveSignaturePath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Supprime définitivement un enfant et toutes ses données liées (parents, plannings, vaccins, médicaments, maladies).
  Future<void> deleteChild(int id) async {
    final db = await _db;
    await db.transaction<void>((txn) async {
      final patterns = await txn.query(
        'weekly_patterns',
        columns: ['id'],
        where: 'child_id = ?',
        whereArgs: [id],
      );
      for (final p in patterns) {
        final patternId = p['id'] as int;
        await txn.delete('schedules', where: 'pattern_id = ?', whereArgs: [patternId]);
      }
      await txn.delete('weekly_patterns', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete('parents', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete('vaccinations', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete('medications', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete('diseases', where: 'child_id = ?', whereArgs: [id]);
      await txn.delete('children', where: 'id = ?', whereArgs: [id]);
    });
  }
}

