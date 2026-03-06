import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String?> savePickedPhoto(XFile file, {int? childId}) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(dir.path, 'children_photos'));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    final name = childId != null
        ? 'child_$childId.jpg'
        : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final destPath = p.join(photoDir.path, name);
    final bytes = await file.readAsBytes();
    await File(destPath).writeAsBytes(bytes);
    return destPath;
  } catch (_) {
    return null;
  }
}

/// Miniature pour une photo de justificatif (reçu du parent).
Widget buildJustificationPhotoThumbnail(String path, {double size = 56}) {
  final file = File(path);
  if (!file.existsSync()) {
    return Icon(Icons.broken_image, size: size);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.cover,
    ),
  );
}

/// Ouvre une boîte de dialogue pour afficher la photo justificatif en grand (contrôle du document).
void showJustificationPhotoViewer(BuildContext context, String path) {
  final file = File(path);
  if (!file.existsSync()) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image introuvable.')));
    return;
  }
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.9, maxHeight: MediaQuery.of(ctx).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Photo justificatif', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Enregistre la signature saisie lors de l'archivage d'un enfant (déclaration arrivée/départ).
Future<String?> saveArchiveSignature(int childId, Uint8List bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final archiveDir = Directory(p.join(dir.path, 'archive_signatures'));
    if (!await archiveDir.exists()) await archiveDir.create(recursive: true);
    final path = p.join(archiveDir.path, 'child_$childId.png');
    await File(path).writeAsBytes(bytes);
    return path;
  } catch (_) {
    return null;
  }
}

/// Enregistre la signature de l'assistant (profil) pour les déclarations arrivée/départ.
Future<String?> saveAssistantSignature(Uint8List bytes) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'assistant_signature.png');
    await File(path).writeAsBytes(bytes);
    return path;
  } catch (_) {
    return null;
  }
}

/// Charge les octets de la signature assistant (pour le PDF déclaration).
Future<Uint8List?> loadAssistantSignatureBytes(String? path) async {
  if (path == null || path.isEmpty) return null;
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Charge les octets d'une photo justificatif (pour PDF).
Future<Uint8List?> loadJustificationPhotoBytes(String path) async {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Enregistre une photo de justificatif de vaccination (reçu du parent).
/// Si la même photo (même contenu) est déjà enregistrée, réutilise le fichier existant
/// au lieu de dupliquer, pour économiser l'espace.
Future<String?> saveVaccinationJustificationPhoto(XFile file, {required int childId, required int ruleId}) async {
  try {
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final dir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(dir.path, 'vaccination_justifications'));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    final name = '$hash.jpg';
    final destPath = p.join(photoDir.path, name);
    final destFile = File(destPath);
    if (!await destFile.exists()) {
      await destFile.writeAsBytes(bytes);
    }
    return destPath;
  } catch (_) {
    return null;
  }
}

bool get isPhotoSupported => true;

Widget buildChildPhotoAvatar({
  required BuildContext context,
  String? photoPath,
  required String initial,
  double radius = 24,
}) {
  if (photoPath != null && photoPath.isNotEmpty) {
    final file = File(photoPath);
    if (file.existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(file),
      );
    }
  }
  return CircleAvatar(
    radius: radius,
    child: Text(
      initial.isNotEmpty ? initial.characters.first.toUpperCase() : '?',
      style: TextStyle(fontSize: radius * 0.8),
    ),
  );
}
