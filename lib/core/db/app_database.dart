import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

class AppDatabase {
  AppDatabase();

  /// Nom du fichier SQLite dans le dossier Documents (sauvegarde iCloud, etc.).
  static const String dbFileName = 'assistante_maternelle.db';

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    if (kIsWeb) {
      throw UnsupportedError('SQLite non disponible sur Web');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, dbFileName);

    final db = await openDatabase(
      dbPath,
      version: DbMigrations.currentVersion,
      onCreate: DbMigrations.onCreate,
      onUpgrade: DbMigrations.onUpgrade,
    );

    _db = db;
    return db;
  }

  /// À appeler avant une copie externe du fichier .db (sauvegarde iCloud, export).
  Future<void> checkpointWal() async {
    final db = await database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL)');
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) {
      await db.close();
    }
  }
}

