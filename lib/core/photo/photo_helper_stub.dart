import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Sur plateforme web : pas de stockage fichier, pas d'affichage par chemin.
Future<String?> savePickedPhoto(XFile file, {int? childId}) async => null;

Future<String?> saveVaccinationJustificationPhoto(XFile file, {required int childId, required int ruleId}) async => null;

Widget buildJustificationPhotoThumbnail(String path, {double size = 56}) {
  return Icon(Icons.broken_image, size: size);
}

void showJustificationPhotoViewer(BuildContext context, String path) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Photo justificatif'),
      content: const Text('Affichage non disponible sur cette plateforme.'),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
    ),
  );
}

Future<Uint8List?> loadJustificationPhotoBytes(String path) async => null;

Future<String?> saveArchiveSignature(int childId, Uint8List bytes) async => null;

Future<String?> saveAssistantSignature(Uint8List bytes) async => null;

Future<Uint8List?> loadAssistantSignatureBytes(String? path) async => null;

bool get isPhotoSupported => false;

Widget buildChildPhotoAvatar({
  required BuildContext context,
  String? photoPath,
  required String initial,
  double radius = 24,
}) {
  return CircleAvatar(
    radius: radius,
    child: Text(
      initial.isNotEmpty ? initial.characters.first.toUpperCase() : '?',
      style: TextStyle(fontSize: radius * 0.8),
    ),
  );
}
