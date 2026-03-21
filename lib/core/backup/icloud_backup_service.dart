import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';

/// Sauvegarde / restauration des données (base SQLite + dossiers photos) vers le conteneur iCloud Drive de l’app.
///
/// N’est disponible que sur **iOS** avec iCloud activé et le même compte Apple sur chaque appareil.
/// La synchro n’est pas instantanée : iOS peut mettre quelques minutes à propager le fichier.
class IcloudBackupService {
  IcloudBackupService._();

  static const _channel = MethodChannel('fr.tual.nousnous/icloud');
  static const _backupZipName = 'nousnous_backup.zip';

  static const _photoDirs = [
    'children_photos',
    'vaccination_justifications',
    'doliprane_prescriptions',
    'archive_signatures',
  ];

  static bool get isSupported => !kIsWeb && Platform.isIOS;

  /// true si le conteneur iCloud est accessible sur cet appareil.
  static Future<bool> isICloudAvailable() async {
    if (!isSupported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('isUbiquityAvailable');
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Dernière date de modification du fichier de sauvegarde dans iCloud (null si absent ou erreur).
  static Future<DateTime?> remoteBackupModified() async {
    if (!isSupported) return null;
    try {
      final ms = await _channel.invokeMethod<int>('backupModifiedMillis');
      if (ms == null || ms <= 0) return null;
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
    } on PlatformException {
      return null;
    }
  }

  /// Indique si un fichier `nousnous_backup.zip` existe dans Documents iCloud de l’app.
  static Future<bool> hasRemoteBackup() async {
    if (!isSupported) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('backupExists');
      return ok ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Ferme la base, crée un ZIP (Documents) et le copie dans iCloud. Rouvre la base ensuite.
  static Future<void> uploadBackup(AppDatabase db) async {
    if (!isSupported) {
      throw StateError('Sauvegarde iCloud : uniquement sur iPhone/iPad.');
    }
    final available = await isICloudAvailable();
    if (!available) {
      throw StateError('iCloud indisponible. Vérifiez la connexion et que iCloud Drive est activé.');
    }

    final docs = await getApplicationDocumentsDirectory();
    final docsPath = docs.path;

    await db.checkpointWal();
    await db.close();

    try {
      final archive = Archive();
      final dbFile = File(p.join(docsPath, AppDatabase.dbFileName));
      if (await dbFile.exists()) {
        archive.addFile(ArchiveFile.bytes(AppDatabase.dbFileName, await dbFile.readAsBytes()));
      }

      for (final dirName in _photoDirs) {
        final dir = Directory(p.join(docsPath, dirName));
        await _addDirectoryToArchive(archive, dir, docsPath);
      }

      final sig = File(p.join(docsPath, 'assistant_signature.png'));
      if (await sig.exists()) {
        archive.addFile(ArchiveFile.bytes('assistant_signature.png', await sig.readAsBytes()));
      }

      final zipBytes = ZipEncoder().encode(archive);
      final tempDir = await getTemporaryDirectory();
      final localZip = File(p.join(tempDir.path, _backupZipName));
      await localZip.writeAsBytes(zipBytes, flush: true);

      final ok = await _channel.invokeMethod<bool>('copyToICloud', <String, dynamic>{
        'localPath': localZip.path,
        'destName': _backupZipName,
      });
      if (ok != true) {
        throw StateError('Échec de la copie vers iCloud.');
      }
    } finally {
      await db.database;
    }
  }

  /// Télécharge le ZIP depuis iCloud, ferme la base, extrait dans Documents (écrase les fichiers), rouvre la base.
  static Future<void> restoreBackup(AppDatabase db) async {
    if (!isSupported) {
      throw StateError('Restauration iCloud : uniquement sur iPhone/iPad.');
    }
    final available = await isICloudAvailable();
    if (!available) {
      throw StateError('iCloud indisponible.');
    }
    final exists = await hasRemoteBackup();
    if (!exists) {
      throw StateError('Aucune sauvegarde trouvée sur iCloud.');
    }

    final tempDir = await getTemporaryDirectory();
    final localZip = File(p.join(tempDir.path, 'nousnous_restore_${DateTime.now().millisecondsSinceEpoch}.zip'));

    final ok = await _channel.invokeMethod<bool>('copyFromICloud', <String, dynamic>{
      'destLocalPath': localZip.path,
      'sourceName': _backupZipName,
    });
    if (ok != true || !await localZip.exists()) {
      throw StateError('Impossible de récupérer la sauvegarde depuis iCloud.');
    }

    final docs = await getApplicationDocumentsDirectory();
    final docsPath = docs.path;

    await db.close();

    try {
      final bytes = await localZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        if (!file.isFile) continue;
        final name = file.name.replaceAll('\\', '/');
        if (name.contains('..')) continue;
        final target = File(p.join(docsPath, name));
        await target.parent.create(recursive: true);
        final content = file.content;
        await target.writeAsBytes(content, flush: true);
      }
    } finally {
      try {
        await localZip.delete();
      } catch (_) {}
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
