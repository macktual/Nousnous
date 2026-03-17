import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../models/doliprane_prescription_model.dart';

class DolipraneLocalDatasource {
  DolipraneLocalDatasource(this._db);

  final AppDatabase _db;

  Future<Database> get _database async => _db.database;

  Future<List<DolipranePrescriptionModel>> getForChild(int childId) async {
    final db = await _database;
    final rows = await db.query(
      'doliprane_prescriptions',
      where: 'child_id = ?',
      whereArgs: [childId],
      orderBy: 'end_date DESC',
    );
    return rows.map(DolipranePrescriptionModel.fromMap).toList();
  }

  Future<DolipranePrescriptionModel> insert(DolipranePrescriptionModel model) async {
    final db = await _database;
    final map = model.toMap();
    map.remove('id');
    final id = await db.insert('doliprane_prescriptions', map);
    return DolipranePrescriptionModel(
      id: id,
      childId: model.childId,
      startDate: model.startDate,
      endDate: model.endDate,
      prescriptionDate: model.prescriptionDate,
      childWeightKg: model.childWeightKg,
      weightDate: model.weightDate,
      reminderWeeksBeforeEnd: model.reminderWeeksBeforeEnd,
      photoPath: model.photoPath,
    );
  }

  Future<void> update(DolipranePrescriptionModel model) async {
    final db = await _database;
    await db.update(
      'doliprane_prescriptions',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [model.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete(
      'doliprane_prescriptions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
