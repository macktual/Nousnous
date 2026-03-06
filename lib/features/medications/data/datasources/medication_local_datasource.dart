import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../models/medication_entry_model.dart';

class MedicationLocalDatasource {
  MedicationLocalDatasource(this._db);

  final AppDatabase _db;

  Future<Database> get _database async => _db.database;

  Future<List<MedicationEntryModel>> getForChild(int childId) async {
    final db = await _database;
    final rows = await db.query(
      'medications',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date_time DESC',
    );
    return rows.map(MedicationEntryModel.fromMap).toList();
  }

  Future<MedicationEntryModel> insert(MedicationEntryModel model) async {
    final db = await _database;
    final map = model.toMap();
    map.remove('id');
    final id = await db.insert('medications', map);
    return MedicationEntryModel(
      id: id,
      childId: model.childId,
      dateTime: model.dateTime,
      medicationName: model.medicationName,
      posology: model.posology,
      reason: model.reason,
      administeredBy: model.administeredBy,
      notes: model.notes,
    );
  }

  Future<void> update(MedicationEntryModel model) async {
    final db = await _database;
    await db.update(
      'medications',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retourne la liste des noms de médicaments distincts (tous enfants confondus).
  Future<List<String>> getDistinctMedicationNames() async {
    final db = await _database;
    final rows = await db.rawQuery(
      '''
SELECT DISTINCT medication_name
FROM medications
WHERE medication_name IS NOT NULL AND medication_name != ''
ORDER BY LOWER(medication_name)
''',
    );
    return rows
        .map((r) => r['medication_name'])
        .whereType<String>()
        .toList();
  }
}
