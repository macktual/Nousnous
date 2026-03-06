import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/children/domain/entities/child.dart';
import '../../features/medications/domain/entities/medication_entry.dart';
import 'pdf_theme.dart';

final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

/// Génère un PDF récapitulatif des médicaments à partir des entrées.
Future<pw.Document> buildMedicationsPdfFromEntries(
  Child child,
  List<MedicationEntry> entries,
) async {
  final theme = await getPdfTheme();
  final pdf = pw.Document(theme: theme);
  final editionDate = DateTime.now();
  final editionFmt = DateFormat('dd/MM/yyyy');
  pdf.addPage(
    pw.MultiPage(
      header: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Suivi d\'administration de médicament de ${child.firstName} ${child.lastName}',
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
          'Date d\'édition : ${editionFmt.format(editionDate)}',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2), // Date / Heure
            1: const pw.FlexColumnWidth(1.5), // Médicament
            2: const pw.FlexColumnWidth(1.0), // Posologie
            3: const pw.FlexColumnWidth(1.2), // Motif
            4: const pw.FlexColumnWidth(1.2), // Observation
            5: const pw.FlexColumnWidth(1.2), // Administrée par
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Date / Heure', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Médicament', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Posologie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Motif', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Observation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text('Administrée par', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-')),
                  pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-')),
                ],
              )
            else
              for (final e in entries)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(_dateTimeFormat.format(e.dateTime)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(e.medicationName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(e.posology ?? '-'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        (e.reason != null && e.reason!.isNotEmpty) ? e.reason! : '-',
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        (e.notes != null && e.notes!.isNotEmpty) ? e.notes! : '-',
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        (e.administeredBy != null && e.administeredBy!.isNotEmpty) ? e.administeredBy! : '-',
                      ),
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

/// Génère un PDF des médicaments (sans liste : pour compatibilité archive).
Future<pw.Document> buildMedicationsPdf(Child child) async {
  return buildMedicationsPdfFromEntries(child, []);
}
