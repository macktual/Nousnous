import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/children/domain/entities/child.dart';
import '../../features/children/domain/entities/parent.dart';
import '../../features/children/domain/entities/weekly_pattern.dart';
import 'pdf_theme.dart';

/// Génère un PDF récapitulatif du contrat (enfant, parents, horaires).
Future<pw.Document> buildContractPdf(Child child) async {
  final theme = await getPdfTheme();
  final pdf = pw.Document(theme: theme);
  final editionDate = DateTime.now();
  final editionFmt = DateFormat('dd/MM/yyyy');
  String fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  pdf.addPage(
    pw.MultiPage(
      header: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Fiche enfant - ${child.firstName} ${child.lastName}',
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
        pw.Text('Enfant', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text('Nom : ${child.lastName}'),
        pw.Text('Prénom : ${child.firstName}'),
        pw.Text('Date de naissance : ${fmt(child.birthDate)}'),
        pw.Text('Début de contrat : ${fmt(child.contractStartDate)}'),
        if (child.contractEndDate != null)
          pw.Text('Fin de contrat : ${fmt(child.contractEndDate!)}'),
        pw.SizedBox(height: 12),
        pw.Text('Parents', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        for (final p in child.parents) ...[
          pw.Text('${p.role == "parent1" ? "Parent 1" : "Parent 2"} : ${p.firstName} ${p.lastName}'),
          pw.Text('Adresse : ${_parentFullAddress(p)}'),
          if (p.phone.isNotEmpty) pw.Text('Téléphone : ${p.phone}'),
          if (p.email.isNotEmpty) pw.Text('Email : ${p.email}'),
          pw.SizedBox(height: 6),
        ],
        pw.SizedBox(height: 12),
        pw.Text('Horaires', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        ..._buildHorairesHistory(child.weeklyPatterns, child.contractStartDate, fmt),
      ],
    ),
  );

  return pdf;
}

/// Groupe les patterns par date de prise d'effet et produit les widgets pour l'historique.
List<pw.Widget> _buildHorairesHistory(
  List<WeeklyPattern> patterns,
  DateTime contractStartDate,
  String Function(DateTime) fmt,
) {
  if (patterns.isEmpty) return [];
  final byDate = <DateTime?, List<WeeklyPattern>>{};
  for (final p in patterns) {
    byDate.putIfAbsent(p.validFrom, () => []).add(p);
  }
  final keys = byDate.keys.toList()
    ..sort((a, b) {
      if (a == null && b == null) return 0;
      if (a == null) return -1;
      if (b == null) return 1;
      return a.compareTo(b);
    });
  final out = <pw.Widget>[];
  for (final validFrom in keys) {
    final periodPatterns = byDate[validFrom]!;
    final effectiveDate = validFrom ?? contractStartDate;
    out.add(pw.Text(
      validFrom == null
          ? 'Horaires à compter du ${fmt(effectiveDate)} (début de contrat)'
          : 'Nouveaux horaires à compter du ${fmt(effectiveDate)}',
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ));
    out.add(pw.SizedBox(height: 2));
    for (final pattern in periodPatterns) {
      out.add(pw.Text(pattern.name, style: const pw.TextStyle(fontSize: 10)));
      for (final e in pattern.entries) {
        out.add(pw.Text(
          '  ${_weekday(e.weekday)} : ${e.arrivalTime ?? "-"} -> ${e.departureTime ?? "-"}',
          style: const pw.TextStyle(fontSize: 10),
        ));
      }
      out.add(pw.SizedBox(height: 4));
    }
    out.add(pw.SizedBox(height: 8));
  }
  return out;
}

String _weekday(int w) {
  const l = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
  return w >= 1 && w <= 5 ? l[w] : 'Jour $w';
}

String _parentFullAddress(ParentInfo p) {
  final parts = <String>[];
  if (p.address.isNotEmpty) parts.add(p.address);
  if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
  if (p.city != null && p.city!.isNotEmpty) parts.add(p.city!);
  return parts.isEmpty ? '' : parts.join(', ');
}
