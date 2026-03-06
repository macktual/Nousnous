import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/children/domain/entities/child.dart';
import '../../features/vaccinations/domain/entities/vaccination_entry.dart';
import 'pdf_theme.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

/// Vaccin en retard : date théorique dépassée et non fait.
bool _isOverdue(VaccinationEntry e) {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final theoretical = DateTime(e.theoreticalDate.year, e.theoreticalDate.month, e.theoreticalDate.day);
  return !e.isDone && theoretical.isBefore(today);
}

String _justificationLabel(VaccinationEntry e) {
  if (!e.isDone) return '-';
  final parts = <String>[];
  if (e.justificationSource != null && e.justificationSource!.trim().isNotEmpty) {
    parts.add(e.justificationSource!.trim());
  }
  if (e.justificationDate != null) {
    parts.add(_dateFormat.format(e.justificationDate!));
  }
  if (e.justificationPhotoPath != null && e.justificationPhotoPath!.isNotEmpty) {
    parts.add('Photo');
  }
  return parts.isEmpty ? '-' : parts.join(', ');
}

/// Génère un PDF récapitulatif des vaccinations à partir des entrées.
/// [justificationPhotoBytes] : liste optionnelle d'octets des photos justificatifs (même ordre que [entries]) pour afficher les vignettes.
Future<pw.Document> buildVaccinationsPdfFromEntries(
  Child child,
  List<VaccinationEntry> entries, {
  List<Uint8List?>? justificationPhotoBytes,
}) async {
  final theme = await getPdfTheme();
  final pdf = pw.Document(theme: theme);
  final editionDate = DateTime.now();
  final hasPhotoColumn = justificationPhotoBytes != null && justificationPhotoBytes.length == entries.length;

  double getVignetteSize() => 36;

  pdf.addPage(
    pw.MultiPage(
      header: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Vaccinations - ${child.firstName} ${child.lastName}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Date d\'édition : ${_dateFormat.format(editionDate)}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.8),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(0.7),
            4: const pw.FlexColumnWidth(1.2),
            if (hasPhotoColumn) 5: const pw.FlexColumnWidth(0.8),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Vaccin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Date théorique', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Date réelle', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Statut', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Justificatif', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                if (hasPhotoColumn)
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('Photo justificatif', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
              ],
            ),
            for (var i = 0; i < entries.length; i++) ...[
              _buildRow(entries[i], hasPhotoColumn ? justificationPhotoBytes![i] : null, getVignetteSize(), hasPhotoColumn, _isOverdue, _justificationLabel, _dateFormat),
            ],
          ],
        ),
      ],
    ),
  );
  return pdf;
}

pw.TableRow _buildRow(
  VaccinationEntry e,
  Uint8List? photoBytes,
  double vignetteSize,
  bool includePhotoColumn,
  bool Function(VaccinationEntry) isOverdue,
  String Function(VaccinationEntry) justificationLabel,
  DateFormat dateFormat,
) {
  final overdue = isOverdue(e);
  final style = overdue ? pw.TextStyle(color: PdfColors.red) : null;
  final cells = <pw.Widget>[
    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.rule.name, style: style)),
    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(dateFormat.format(e.theoreticalDate), style: style)),
    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.actualDate != null ? dateFormat.format(e.actualDate!) : '-', style: style)),
    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.isDone ? 'Fait' : 'À faire', style: style)),
    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(justificationLabel(e), style: style)),
  ];
  if (includePhotoColumn) {
    if (photoBytes != null && photoBytes.isNotEmpty) {
cells.add(
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Center(
          child: pw.Image(
            pw.MemoryImage(photoBytes),
            width: vignetteSize,
            height: vignetteSize,
            fit: pw.BoxFit.cover,
          ),
        ),
      ),
    );
    } else {
      cells.add(pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-', style: style)));
    }
  }
  return pw.TableRow(children: cells);
}

/// Ancienne signature pour compatibilité (archive) : appelle avec liste vide puis données à charger côté appelant.
Future<pw.Document> buildVaccinationsPdf(Child child) async {
  return buildVaccinationsPdfFromEntries(child, []);
}
