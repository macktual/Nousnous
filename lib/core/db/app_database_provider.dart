import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Une seule instance SQLite pour toute l’app (sauvegarde iCloud, cohérence des connexions).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});
