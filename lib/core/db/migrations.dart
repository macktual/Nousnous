import 'package:sqflite/sqflite.dart';

class DbMigrations {
  static const int currentVersion = 20;

  static Future<void> onCreate(Database db, int version) async {
    await _migration1(db);
    if (version >= 2) await _migration2(db);
    if (version >= 3) await _migration3(db);
    if (version >= 4) await _migration4(db);
    if (version >= 5) await _migration5(db);
    if (version >= 6) await _migration6(db);
    if (version >= 7) await _migration7(db);
    if (version >= 8) await _migration8(db);
    if (version >= 9) await _migration9(db);
    if (version >= 10) await _migration10(db);
    if (version >= 11) await _migration11(db);
    if (version >= 12) await _migration12(db);
    if (version >= 13) await _migration13(db);
    if (version >= 14) await _migration14(db);
    if (version >= 15) await _migration15(db);
    if (version >= 16) await _migration16(db);
    if (version >= 17) await _migration17(db);
    if (version >= 18) await _migration18(db);
    if (version >= 19) await _migration19(db);
    if (version >= 20) await _migration20(db);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    var v = oldVersion;
    while (v < newVersion) {
      v++;
      switch (v) {
        case 1:
          await _migration1(db);
          break;
        case 2:
          await _migration2(db);
          break;
        case 3:
          await _migration3(db);
          break;
        case 4:
          await _migration4(db);
          break;
        case 5:
          await _migration5(db);
          break;
        case 6:
          await _migration6(db);
          break;
        case 7:
          await _migration7(db);
          break;
        case 8:
          await _migration8(db);
          break;
        case 9:
          await _migration9(db);
          break;
        case 10:
          await _migration10(db);
          break;
        case 11:
          await _migration11(db);
          break;
        case 12:
          await _migration12(db);
          break;
        case 13:
          await _migration13(db);
          break;
        case 14:
          await _migration14(db);
          break;
        case 15:
          await _migration15(db);
          break;
        case 16:
          await _migration16(db);
          break;
        case 17:
          await _migration17(db);
          break;
        case 18:
          await _migration18(db);
          break;
        case 19:
          await _migration19(db);
          break;
        case 20:
          await _migration20(db);
          break;
      }
    }
  }

  static Future<void> _migration20(Database db) async {
    // Pneumocoque : ajouter la dénomination VAXNEUVANCE® (paramètres pour éviter les soucis de guillemets SQL)
    await db.rawUpdate(
      "UPDATE vaccination_rules SET name = ? WHERE name LIKE ?",
      ['Pneumocoque (1) - 2 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®', 'Pneumocoque (1)%'],
    );
    await db.rawUpdate(
      "UPDATE vaccination_rules SET name = ? WHERE name LIKE ?",
      ['Pneumocoque (2) - 4 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®', 'Pneumocoque (2)%'],
    );
    await db.rawUpdate(
      "UPDATE vaccination_rules SET name = ? WHERE name LIKE ?",
      ['Pneumocoque (3) - 11 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®', 'Pneumocoque (3)%'],
    );
  }

  static Future<void> _migration19(Database db) async {
    try {
      await db.execute('ALTER TABLE weekly_patterns ADD COLUMN valid_from TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE weekly_patterns ADD COLUMN valid_until TEXT');
    } catch (_) {}
  }

  static Future<void> _migration18(Database db) async {
    try {
      await db.execute('ALTER TABLE children ADD COLUMN archive_signature_path TEXT');
    } catch (_) {}
  }

  static Future<void> _migration17(Database db) async {
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN signature_path TEXT');
    } catch (_) {}
  }

  static Future<void> _migration16(Database db) async {
    // Hépatite B : retirer " ou inclus hexavalent", mettre ENGERIX®/HBVAXPRO® à chaque dose
    await db.update(
      'vaccination_rules',
      {'name': 'Hépatite B (1) - 2 mois - ENGERIX®, HBVAXPRO®'},
      where: "name LIKE 'Hépatite B (1)%'",
    );
    await db.update(
      'vaccination_rules',
      {'name': 'Hépatite B (2) - 4 mois - ENGERIX®, HBVAXPRO®'},
      where: "name LIKE 'Hépatite B (2)%'",
    );
    await db.update(
      'vaccination_rules',
      {'name': 'Hépatite B (3) - 11 mois - ENGERIX®, HBVAXPRO®'},
      where: "name LIKE 'Hépatite B (3)%'",
    );
  }

  static Future<void> _migration15(Database db) async {
    try {
      await db.execute('ALTER TABLE children ADD COLUMN vaccination_scheme TEXT');
    } catch (_) {}
    // Hib : nom du produit Infanrixquinta ou Pentavac (par nom pour éviter de toucher aux autres schémas)
    await db.update(
      'vaccination_rules',
      {'name': 'Hib (1) - 2 mois - INFANRIXQUINTA®, PENTAVAC®'},
      where: "name LIKE 'Hib (1)%'",
    );
    await db.update(
      'vaccination_rules',
      {'name': 'Hib (2) - 4 mois - INFANRIXQUINTA®, PENTAVAC®'},
      where: "name LIKE 'Hib (2)%'",
    );
    await db.update(
      'vaccination_rules',
      {'name': 'Hib (3) - 11 mois - INFANRIXQUINTA®, PENTAVAC®'},
      where: "name LIKE 'Hib (3)%'",
    );
  }

  static Future<void> _migration14(Database db) async {
    try {
      await db.execute('ALTER TABLE vaccinations ADD COLUMN justification_source TEXT');
    } catch (_) {}
  }

  static Future<void> _migration13(Database db) async {
    try {
      await db.execute('ALTER TABLE vaccinations ADD COLUMN has_justification INTEGER DEFAULT 0');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE vaccinations ADD COLUMN justification_date TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE vaccinations ADD COLUMN justification_photo_path TEXT');
    } catch (_) {}
  }

  static Future<void> _migration12(Database db) async {
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN access_code TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN floor TEXT');
    } catch (_) {}
  }

  static Future<void> _migration11(Database db) async {
    try {
      await db.execute('ALTER TABLE parents ADD COLUMN postal_code TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE parents ADD COLUMN city TEXT');
    } catch (_) {}
  }

  static Future<void> _migration10(Database db) async {
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN agreement_max_children INTEGER');
    } catch (_) {}
  }

  static Future<void> _migration9(Database db) async {
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN civility TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN postal_code TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN city TEXT');
    } catch (_) {}
  }

  /// Calendrier vaccinal officiel DGS 2025 (support au contrôle des vaccinations).
  static Future<void> _migration8(Database db) async {
    try {
      await db.execute('ALTER TABLE vaccination_rules ADD COLUMN notes TEXT');
    } catch (_) {}

    final countResult = await db.rawQuery('SELECT COUNT(*) as c FROM vaccination_rules');
    final count = (countResult.first['c'] as int?) ?? 0;

    if (count == 13) {
      // Nouvelles installs (13 règles) : ajout des notes sur les règles concernées
      await db.update(
        'vaccination_rules',
        {'notes': 'À partir du 01/01/2025 : ACWY remplace Méningocoque C. Si vacciné avant avec 2 doses MenC (NEISVAC®, MENJUGATE®), schéma complet. 1 dose à 6 mois (NIMENRIX®) + rappel 12 mois (NIMENRIX® ou MENQUADFI®).'},
        where: "name LIKE ?",
        whereArgs: ['%ACWY (2)%'],
      );
      await db.update(
        'vaccination_rules',
        {'notes': 'À partir du 01/01/2025 remplace Méningocoque C. Voir note ACWY (2).'},
        where: "name LIKE ?",
        whereArgs: ['%ACWY (1)%'],
      );
      await db.update(
        'vaccination_rules',
        {'notes': 'Hépatite B peut être pratiquée séparément (ENGERIX®, HBVAXPRO®) ou associée à INFANRIXQUINTA®, PENTAVAC®. Même nombre de doses.'},
        where: "name LIKE ? AND delay_months = 2",
        whereArgs: ['%Hépatite B%'],
      );
    } else if (count == 16) {
      // Mise à jour des 16 règles existantes (noms officiels + noms commerciaux)
      const updates = [
        [1, 'DTP-Coq-Hib-Hépatite B (1) - 2 mois - INFANRIX HEXA®, HEXYON®, VAXELIS®'],
        [2, 'DTP-Coq-Hib-Hépatite B (2) - 4 mois - INFANRIX HEXA®, HEXYON®, VAXELIS®'],
        [3, 'DTP-Coq-Hib-Hépatite B (3) - 11 mois - INFANRIX HEXA®, HEXYON®, VAXELIS®'],
        [4, 'Hib (1) - 2 mois - inclus dans hexavalent'],
        [5, 'Hib (2) - 4 mois - inclus dans hexavalent'],
        [6, 'Hib (3) - 11 mois - inclus dans hexavalent'],
        [7, 'Hépatite B (1) - 2 mois - ENGERIX®, HBVAXPRO®'],
        [8, 'Hépatite B (2) - 4 mois - ENGERIX®, HBVAXPRO®'],
        [9, 'Hépatite B (3) - 11 mois - ENGERIX®, HBVAXPRO®'],
        [10, 'Pneumocoque (1) - 2 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®'],
        [11, 'Pneumocoque (2) - 4 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®'],
        [12, 'Pneumocoque (3) - 11 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®'],
        [13, 'ROR (1) - 12 mois - M-M-RVaxPro®, PRIORIX®'],
        [14, 'ROR (2) - 16 mois - M-M-RVaxPro®, PRIORIX®'],
        [15, 'Méningocoques ACWY (2) - 12 mois - NIMENRIX®, MENQUADFI®'],
        [16, 'Rappel DTP - 6 ans (72 mois)'],
      ];
      for (final u in updates) {
        await db.update('vaccination_rules', {'name': u[1] as String}, where: 'id = ?', whereArgs: [u[0] as int]);
      }
      await db.update('vaccination_rules', {
        'notes': 'À partir du 01/01/2025 : ACWY remplace Méningocoque C. Si vacciné avant avec 2 doses MenC (NEISVAC®, MENJUGATE®), schéma complet. 1 dose à 6 mois (NIMENRIX®) + rappel 12 mois (NIMENRIX® ou MENQUADFI®).',
      }, where: 'id = ?', whereArgs: [15]);
      await db.update('vaccination_rules', {
        'notes': 'Hépatite B peut être pratiquée séparément (ENGERIX®, HBVAXPRO®) ou associée à INFANRIXQUINTA®, PENTAVAC®. Même nombre de doses.',
      }, where: 'id = ?', whereArgs: [7]);

      // Ajout des 3 règles manquantes : MenB (1)(2), ACWY (1)
      await db.insert('vaccination_rules', {
        'name': 'Méningocoque B (1) - 2 mois - BEXSERO®',
        'delay_months': 2,
        'sort_order': 17,
      });
      await db.insert('vaccination_rules', {
        'name': 'Méningocoque B (2) - 4 mois - BEXSERO®',
        'delay_months': 4,
        'sort_order': 18,
      });
      await db.insert('vaccination_rules', {
        'name': 'Méningocoques ACWY (1) - 6 mois - NIMENRIX®, MENQUADFI®',
        'delay_months': 6,
        'sort_order': 19,
        'notes': 'À partir du 01/01/2025 remplace Méningocoque C. Voir note ACWY (2).',
      });
    }
  }

  static Future<void> _migration7(Database db) async {
    try {
      await db.execute('ALTER TABLE children ADD COLUMN vacances_scolaires INTEGER');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE children ADD COLUMN particularites_accueil TEXT');
    } catch (_) {}
  }

  static Future<void> _migration6(Database db) async {
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN phone TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN email TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN vacances_scolaires INTEGER');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE assistant ADD COLUMN particularites_accueil_motif_depart TEXT');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE children ADD COLUMN particularites_fin_contrat TEXT');
    } catch (_) {}
  }

  static Future<void> _migration1(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS assistant (
  id INTEGER PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  address TEXT NOT NULL,
  approval_number TEXT NOT NULL,
  approval_date TEXT NOT NULL
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS children (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  birth_date TEXT NOT NULL,
  contract_start_date TEXT NOT NULL,
  contract_end_date TEXT,
  is_archived INTEGER NOT NULL DEFAULT 0,
  current_pattern_id INTEGER,
  photo_path TEXT
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS parents (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL,
  role TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT,
  email TEXT
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS weekly_patterns (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS schedules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pattern_id INTEGER NOT NULL,
  weekday INTEGER NOT NULL,
  arrival_time TEXT,
  departure_time TEXT
);
''');
  }

  static Future<void> _migration2(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS vaccination_rules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  delay_months INTEGER NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);
''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS vaccinations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL,
  rule_id INTEGER NOT NULL,
  actual_date TEXT,
  is_done INTEGER NOT NULL DEFAULT 0
);
''');
    await db.execute('''
CREATE UNIQUE INDEX IF NOT EXISTS idx_vaccinations_child_rule
ON vaccinations(child_id, rule_id);
''');
    // Calendrier vaccinal officiel (DGS 2025 - support au contrôle des vaccinations)
    final existing = await db.rawQuery(
      'SELECT COUNT(*) as c FROM vaccination_rules',
    );
    if (((existing.first['c'] as int?) ?? 0) == 0) {
      const defaults = [
        ['DTP-Coq-Hib-Hépatite B (1) - 2 mois - INFANRIX HEXA®, HEXYON®, VAXELIS®', 2, 1],
        ['DTP-Coq-Hib-Hépatite B (2) - 4 mois - INFANRIX HEXA®, HEXYON®, VAXELIS®', 4, 2],
        ['DTP-Coq-Hib-Hépatite B (3) - 11 mois - INFANRIX HEXA®, HEXYON®, VAXELIS®', 11, 3],
        ['Pneumocoque (1) - 2 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®', 2, 4],
        ['Pneumocoque (2) - 4 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®', 4, 5],
        ['Pneumocoque (3) - 11 mois - PREVENAR 13®, PNEUMOVAX®, VAXNEUVANCE®', 11, 6],
        ['Méningocoque B (1) - 2 mois - BEXSERO®', 2, 7],
        ['Méningocoque B (2) - 4 mois - BEXSERO®', 4, 8],
        ['Méningocoques ACWY (1) - 6 mois - NIMENRIX®, MENQUADFI®', 6, 9],
        ['Méningocoques ACWY (2) - 12 mois - NIMENRIX®, MENQUADFI®', 12, 10],
        ['ROR (1) - 12 mois - M-M-RVaxPro®, PRIORIX®', 12, 11],
        ['ROR (2) - 16 mois - M-M-RVaxPro®, PRIORIX®', 16, 12],
        ['Rappel DTP - 6 ans (72 mois)', 72, 13],
      ];
      for (final row in defaults) {
        await db.insert('vaccination_rules', {
          'name': row[0],
          'delay_months': row[1],
          'sort_order': row[2],
        });
      }
    }
  }

  static Future<void> _migration3(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS medications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL,
  date_time TEXT NOT NULL,
  medication_name TEXT NOT NULL,
  posology TEXT,
  reason TEXT,
  administered_by TEXT,
  notes TEXT
);
''');
    await db.execute('''
CREATE INDEX IF NOT EXISTS idx_medications_child_id ON medications(child_id);
''');
  }

  static Future<void> _migration4(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS diseases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  child_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  date_month INTEGER,
  date_year INTEGER
);
''');
    await db.execute('''
CREATE INDEX IF NOT EXISTS idx_diseases_child_id ON diseases(child_id);
''');
  }

  static Future<void> _migration5(Database db) async {
    try {
      await db.execute('ALTER TABLE diseases ADD COLUMN date_day INTEGER');
    } catch (_) {
      // Colonne déjà présente (création fraîche avec version 5)
    }
  }
}

