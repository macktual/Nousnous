import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Thème PDF avec police Unicode (Roboto) pour afficher correctement
/// les caractères accentués (é, è, à, ç, etc.).
pw.ThemeData? _cachedPdfTheme;

/// Retourne un thème avec police Unicode pour les documents PDF.
/// Utilise Roboto (Google Fonts), mis en cache après le premier chargement.
Future<pw.ThemeData> getPdfTheme() async {
  if (_cachedPdfTheme != null) return _cachedPdfTheme!;
  final baseFont = await PdfGoogleFonts.robotoRegular();
  final boldFont = await PdfGoogleFonts.robotoBold();
  _cachedPdfTheme = pw.ThemeData.withFont(
    base: baseFont,
    bold: boldFont,
  );
  return _cachedPdfTheme!;
}
