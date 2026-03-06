import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/children/domain/entities/child.dart';
import '../../features/diseases/domain/entities/disease_entry.dart';
import 'pdf_theme.dart';

const _monthNames = [
  'Janv.', 'Févr.', 'Mars', 'Avr.', 'Mai', 'Juin',
  'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.',
];

String _formatDate(DiseaseEntry e) {
  if (e.dateMonth != null && e.dateYear != null) {
    final m = e.dateMonth! >= 1 && e.dateMonth! <= 12 ? e.dateMonth! - 1 : 0;
    if (e.dateDay != null && e.dateDay! >= 1 && e.dateDay! <= 31) {
      return '${e.dateDay} ${_monthNames[m]} ${e.dateYear}';
    }
    return '${_monthNames[m]} ${e.dateYear}';
  }
  if (e.dateYear != null) return e.dateYear.toString();
  return '-';
}

/// Génère un PDF récapitulatif des maladies à partir des entrées.
Future<pw.Document> buildDiseasesPdfFromEntries(
  Child child,
  List<DiseaseEntry> entries,
) async {
  final theme = await getPdfTheme();
  final pdf = pw.Document(theme: theme);
  final editionDate = DateTime.now();
  String fmtEdition(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  pdf.addPage(
    pw.MultiPage(
      header: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Maladies - ${child.firstName} ${child.lastName}',
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
          'Date d\'édition : ${fmtEdition(editionDate)}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Maladie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            if (entries.isEmpty)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Aucune donnée enregistrée.'),
                  ),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-')),
                ],
              )
            else
              for (final e in entries)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(e.name),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(_formatDate(e)),
                    ),
                  ],
                ),
          ],
        ),
      ],
    ),
  );
  return pdf;
}

/// Génère un PDF des maladies (sans liste : pour compatibilité archive).
Future<pw.Document> buildDiseasesPdf(Child child) async {
  return buildDiseasesPdfFromEntries(child, []);
}
