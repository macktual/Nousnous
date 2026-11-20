import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';
import '../notifications/doliprane_notification_service.dart';

/// Sauvegarde / restauration de toutes les données (base SQLite + photos + signatures)
/// dans un fichier .zip choisi par l'utilisatrice (Téléchargements, Google Drive, Fichiers…).
///
/// Fonctionne sur Android et iOS. Sert notamment avant un changement de téléphone
/// ou une réinstallation de l'app (passage d'une version APK à la version Play Store).
class FileBackupService {
  FileBackupService._();

  static const _photoDirs = [
    'children_photos',
    'vaccination_justifications',
    'doliprane_prescriptions',
    'archive_signatures',
  ];

  static const _signatureFile = 'assistant_signature.png';

  static bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Crée la sauvegarde puis ouvre la fenêtre « Enregistrer sous ».
  /// Renvoie false si l'utilisatrice a annulé.
  static Future<bool> exportBackup(AppDatabase db) async {
    final zipBytes = await _buildZip(db);
    final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Enregistrer la sauvegarde easynounou',
      fileName: 'easynounou_sauvegarde_$stamp.zip',
      bytes: zipBytes,
      mimeType: 'application/zip',
    );
    return uri != null;
  }

  /// Fait choisir un fichier de sauvegarde, puis remplace les données de l'app par son contenu.
  /// Renvoie false si l'utilisatrice a annulé.
  static Future<bool> importBackup(AppDatabase db) async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Choisir une sauvegarde easynounou (.zip)',
    );
    if (picked == null) return false;

    final Uint8List bytes;
    try {
      bytes = await picked.readAsBytes();
    } catch (_) {
      throw StateError('Impossible de lire le fichier choisi.');
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw StateError('Ce fichier n’est pas une sauvegarde easynounou.');
    }
    final hasDatabase = archive.files.any((f) => f.isFile && f.name == AppDatabase.dbFileName);
    if (!hasDatabase) {
      throw StateError('Ce fichier n’est pas une sauvegarde easynounou.');
    }

    final docsPath = (await getApplicationDocumentsDirectory()).path;

    await db.close();
    try {
      // Supprime les fichiers temporaires de l'ancienne base pour qu'ils ne
      // soient pas rejoués sur la base restaurée.
      for (final suffix in const ['-wal', '-shm', '-journal']) {
        final f = File(p.join(docsPath, '${AppDatabase.dbFileName}$suffix'));
        if (await f.exists()) await f.delete();
      }
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name.replaceAll('\\', '/');
        if (name.contains('..') || name.startsWith('/')) continue;
        final target = File(p.join(docsPath, name));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(file.content, flush: true);
      }
    } finally {
      await db.database;
    }

    await rescheduleDolipraneReminders(db);
    return true;
  }

  /// Reprogramme les rappels Doliprane à partir de la base (après une restauration :
  /// les notifications programmées ne font pas partie de la sauvegarde).
  static Future<void> rescheduleDolipraneReminders(AppDatabase db) async {
    try {
      final database = await db.database;
      final rows = await database.rawQuery('''
SELECT d.id, d.end_date, d.reminder_weeks_before_end, c.first_name
FROM doliprane_prescriptions d
LEFT JOIN children c ON c.id = d.child_id
WHERE d.reminder_weeks_before_end IS NOT NULL
''');
      await DolipraneNotificationService.cancelAllReminders();
      for (final r in rows) {
        final id = r['id'] as int?;
        final end = DateTime.tryParse((r['end_date'] as String?) ?? '');
        final weeks = r['reminder_weeks_before_end'] as int?;
        if (id == null || end == null || weeks == null) continue;
        await DolipraneNotificationService.scheduleReminder(
          prescriptionId: id,
          reminderDate: end.subtract(Duration(days: weeks * 7)),
          childFirstName: r['first_name'] as String?,
        );
      }
    } catch (_) {
      // Les rappels ne doivent jamais faire échouer une restauration.
    }
  }

  /// Ferme la base, crée le ZIP en mémoire, puis rouvre la base.
  static Future<Uint8List> _buildZip(AppDatabase db) async {
    final docsPath = (await getApplicationDocumentsDirectory()).path;

    await db.checkpointWal();
    await db.close();
    try {
      final archive = Archive();
      final dbFile = File(p.join(docsPath, AppDatabase.dbFileName));
      if (!await dbFile.exists()) {
        throw StateError('Aucune donnée à sauvegarder.');
      }
      archive.addFile(ArchiveFile.bytes(AppDatabase.dbFileName, await dbFile.readAsBytes()));

      for (final dirName in _photoDirs) {
        await _addDirectoryToArchive(archive, Directory(p.join(docsPath, dirName)), docsPath);
      }

      final sig = File(p.join(docsPath, _signatureFile));
      if (await sig.exists()) {
        archive.addFile(ArchiveFile.bytes(_signatureFile, await sig.readAsBytes()));
      }

      return Uint8List.fromList(ZipEncoder().encode(archive));
    } finally {
      await db.database;
    }
  }

  static Future<void> _addDirectoryToArchive(Archive archive, Directory dir, String docsRoot) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: docsRoot);
      if (rel.startsWith('..')) continue;
      archive.addFile(ArchiveFile.bytes(rel.replaceAll('\\', '/'), await entity.readAsBytes()));
    }
  }
}
