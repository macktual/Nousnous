import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../models/disease_entry_model.dart';

class DiseaseLocalDatasource {
  DiseaseLocalDatasource(this._db);

  final AppDatabase _db;

  Future<Database> get _database async => _db.database;

  Future<List<DiseaseEntryModel>> getForChild(int childId) async {
    final db = await _database;
    final rows = await db.query(
      'diseases',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'date_year DESC, date_month DESC, id DESC',
    );
    return rows.map(DiseaseEntryModel.fromMap).toList();
  }

  Future<DiseaseEntryModel> insert(DiseaseEntryModel model) async {
    final db = await _database;
    final map = model.toMap();
    map.remove('id');
    final id = await db.insert('diseases', map);
    return DiseaseEntryModel(
      id: id,
      childId: model.childId,
      name: model.name,
      dateMonth: model.dateMonth,
      dateYear: model.dateYear,
    );
  }

  Future<void> update(DiseaseEntryModel model) async {
    final db = await _database;
    await db.update(
      'diseases',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete(
      'diseases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
