import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../models/assistant_model.dart';

class AssistantLocalDatasource {
  AssistantLocalDatasource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<AssistantModel?> getProfile() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'assistant',
      where: 'id = ?',
      whereArgs: const [1],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AssistantModel.fromMap(rows.first);
  }

  Future<void> upsertProfile(AssistantModel model) async {
    final db = await _appDatabase.database;
    await db.insert(
      'assistant',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

