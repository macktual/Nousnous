// Génère assets/images/app_icon.png (1024×1024) depuis la maquette source.
// Source : assets/images/icon_proposals/icon_v3_01_bebe_joie.png
//
// 1) Détecte le cadre du visuel (hors damier/gris d’aperçu)
// 2) Recadre puis zoom « cover » en carré (remplit tout l’icône iOS)
// 3) Remplace tout pixel damier résiduel par le dégradé de fond
//
// Usage : dart run tool/generate_square_app_icon.dart
// Puis  : dart run flutter_launcher_icons

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

const int outSize = 1024;

/// Pixels grille d’aperçu (gris/blanc très peu saturés).
bool isCheckerboardOrNeutralEdge(int r, int g, int b) {
  if ((r - g).abs() > 18) return false;
  if ((r - b).abs() > 18) return false;
  if ((g - b).abs() > 18) return false;
  final maxc = math.max(r, math.max(g, b));
  final minc = math.min(r, math.min(g, b));
  final spread = maxc - minc;
  final avg = (r + g + b) / 3;
  if (avg < 175) return false;
  if (spread > 22) return false;
  return true;
}

/// Dégradé diagonal (haut-gauche bleu ciel → bas-droite crème), proche du fond de la maquette.
void fillBackgroundGradient(Image img) {
  final w = img.width;
  final h = img.height;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final t = ((x / (w - 1)) + (y / (h - 1))) / 2;
      final r = (195 + 60 * t).round().clamp(0, 255);
      final g = (225 + 30 * t).round().clamp(0, 255);
      final b = (255 - 35 * t).round().clamp(0, 255);
      img.setPixelRgb(x, y, r, g, b);
    }
  }
}

/// Cadre englobant des pixels « contenu » (pas damier).
({int x, int y, int w, int h}) contentBounds(Image src) {
  var minX = src.width;
  var minY = src.height;
  var maxX = 0;
  var maxY = 0;
  var found = false;
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      if (!isCheckerboardOrNeutralEdge(r, g, b)) {
        found = true;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  if (!found) {
    return (x: 0, y: 0, w: src.width, h: src.height);
  }
  return (x: minX, y: minY, w: maxX - minX + 1, h: maxY - minY + 1);
}

void main() {
  final root = Directory.current.path;
  const masterRelative = 'assets/images/icon_proposals/icon_v3_01_bebe_joie.png';
  final masterPath = '$root/$masterRelative';
  final outPath = '$root/assets/images/app_icon.png';

  if (!File(masterPath).existsSync()) {
    stderr.writeln('Fichier source introuvable : $masterPath');
    exit(1);
  }

  final src = decodeImage(File(masterPath).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Impossible de décoder $masterPath');
    exit(1);
  }

  final b = contentBounds(src);
  final margin = math.max(4, (math.max(b.w, b.h) * 0.02).round());
  var cx = b.x - margin;
  var cy = b.y - margin;
  var cw = b.w + 2 * margin;
  var ch = b.h + 2 * margin;
  cx = cx.clamp(0, src.width - 1);
  cy = cy.clamp(0, src.height - 1);
  if (cx + cw > src.width) cw = src.width - cx;
  if (cy + ch > src.height) ch = src.height - cy;

  final cropped = copyCrop(src, x: cx, y: cy, width: cw, height: ch);

  // Zoom pour remplir un carré 1024 (comme un « cover » centré),
  // sans bandes vides sur les côtés.
  final square = copyResizeCropSquare(
    cropped,
    size: outSize,
    interpolation: Interpolation.average,
  );

  final dst = Image(width: outSize, height: outSize, numChannels: 3);
  fillBackgroundGradient(dst);

  for (var y = 0; y < outSize; y++) {
    for (var x = 0; x < outSize; x++) {
      final p = square.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      if (isCheckerboardOrNeutralEdge(r, g, b)) {
        continue;
      }
      dst.setPixelRgb(x, y, r, g, b);
    }
  }

  File(outPath).writeAsBytesSync(encodePng(dst));
  stdout.writeln('OK → $outPath (${outSize}x$outSize) depuis $masterRelative');
}
