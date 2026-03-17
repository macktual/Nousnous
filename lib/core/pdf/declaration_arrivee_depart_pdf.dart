import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/assistant_profile/domain/entities/assistant.dart';
import '../../features/children/domain/entities/child.dart';
import '../../features/children/domain/entities/parent.dart';
import '../../features/children/domain/entities/weekly_pattern.dart';
import 'pdf_theme.dart';

/// Génère un PDF "Déclaration nominative d'arrivée et de départ d'enfant"
/// sur le modèle du formulaire officiel, prérempli avec les données de l'app.
Future<pw.Document> buildDeclarationArriveeDepartPdf({
  required Child child,
  Assistant? assistant,
  String? faitA,
  DateTime? date,
  List<int>? signatureImageBytes,
  Uint8List? logoImageBytes,
}) async {
  final theme = await getPdfTheme();
  final pdf = pw.Document(theme: theme);
  final dateFait = date ?? DateTime.now();
  String fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String getAssistantLine() {
    if (assistant == null) return '.................................................................................';
    final a = assistant!;
    final civility = (a.civility != null && a.civility!.isNotEmpty) ? '${a.civility} ' : '';
    return '$civility${a.lastName} ${a.firstName}';
  }

  /// "Madame", "Monsieur" ou null si non renseigné.
  String? getAssistantCivilityLabel() {
    if (assistant == null || assistant!.civility == null || assistant!.civility!.isEmpty) return null;
    switch (assistant!.civility!) {
      case 'Mme':
        return 'Madame';
      case 'M.':
        return 'Monsieur';
      default:
        return assistant!.civility;
    }
  }

  /// Accord selon la civilité : soussigné/soussignée, domicilié/domiciliée, agréé/agréée.
  bool isAssistantMadame() {
    return assistant?.civility != null && assistant!.civility == 'Mme';
  }

  /// Ligne nom complète pour le formulaire : "Madame NOM Prénom" ou "Monsieur NOM Prénom" ou "Monsieur / Madame NOM Prénom".
  String getAssistantFormalLine() {
    if (assistant == null) return 'Monsieur / Madame .................................................................................';
    final a = assistant!;
    final name = '${a.lastName} ${a.firstName}';
    final label = getAssistantCivilityLabel();
    if (label != null) return '$label $name';
    return 'Monsieur / Madame $name';
  }

  String getAssistantAddress() {
    if (assistant == null) return '.................................................................................';
    final a = assistant!;
    final parts = <String>[];
    if (a.address.isNotEmpty) parts.add(a.address);
    if (a.postalCode != null && a.postalCode!.isNotEmpty && a.city != null && a.city!.isNotEmpty) {
      parts.add('${a.postalCode} ${a.city}');
    } else if (a.postalCode != null && a.postalCode!.isNotEmpty) {
      parts.add(a.postalCode!);
    } else if (a.city != null && a.city!.isNotEmpty) {
      parts.add(a.city!);
    }
    if (parts.isEmpty) return '.................................................................................';
    return parts.join(', ');
  }

  String getAssistantApprovalDate() {
    if (assistant == null) return '..../..../........';
    return fmt(assistant!.approvalDate);
  }

  String getAssistantApprovalNumber() {
    if (assistant == null || assistant!.approvalNumber.isEmpty) return '........................';
    return assistant!.approvalNumber;
  }

  /// Texte "pour 1 enfant" ou "pour X enfants" (pluriel).
  String getAgreementChildrenLine() {
    final n = assistant?.agreementMaxChildren;
    if (n == null || n < 1 || n > 4) return '';
    if (n == 1) return ' pour 1 enfant';
    return ' pour $n enfants';
  }

  String getAssistantPhone() {
    if (assistant == null || assistant!.phone == null || assistant!.phone!.isEmpty) return '........................';
    return assistant!.phone!;
  }

  String getAssistantEmail() {
    if (assistant == null || assistant!.email == null || assistant!.email!.isEmpty) return '........................';
    return assistant!.email!;
  }

  /// true si code d'accès et étage sont renseignés (pour afficher la rubrique dans le PDF).
  bool _hasAccessAndFloor() {
    if (assistant == null) return false;
    final ac = assistant!.accessCode?.trim() ?? '';
    final fl = assistant!.floor?.trim() ?? '';
    return ac.isNotEmpty && fl.isNotEmpty;
  }

  // Horaires : 1 = Lundi ... 7 = Dimanche.
  const jours = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  String heureArriveeForPattern(dynamic pattern, int jour) {
    for (final e in pattern.entries) {
      if (e.weekday == jour) return e.arrivalTime ?? '';
    }
    return '';
  }
  String heureDepartForPattern(dynamic pattern, int jour) {
    for (final e in pattern.entries) {
      if (e.weekday == jour) return e.departureTime ?? '';
    }
    return '';
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return pw.Container(
          color: PdfColors.white,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Ligne 1 : numéro d'agrément fixe 034.988 (à gauche), logo à droite
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Numéro d'agrément : 034.988",
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (logoImageBytes != null && logoImageBytes.isNotEmpty)
                    pw.Image(pw.MemoryImage(logoImageBytes), height: 52, fit: pw.BoxFit.contain),
                ],
              ),
            pw.SizedBox(height: 8),
            // Bloc titre gris : titre + "(1 fiche par enfant)" (identique au Word)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                color: PdfColors.grey300,
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    "DECLARATION NOMINATIVE\nD'ARRIVEE ET DE DEPART D'ENFANT",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '(1 fiche par enfant)',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Document à transmettre obligatoirement au Pôle Santé/secrétariat chargé des AM de votre domicile, '
              'entièrement complété, dans les 8 jours suivant l\'arrivée ou le départ du ou des enfants '
              '(cf. Décret n° 2006-1153 du 14 septembre 2006, art. R. 421-39).',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '-> La date d\'accueil du 1er enfant conditionne l\'inscription à la 2ème partie de la formation obligatoire.',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, decoration: pw.TextDecoration.underline),
            ),
            pw.SizedBox(height: 12),
            // Assistant
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                isAssistantMadame() ? 'Je soussignée, ' : 'Je soussigné, ',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Text(
              getAssistantFormalLine(),
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              isAssistantMadame() ? 'Domiciliée : ${getAssistantAddress()}' : 'Domicilié : ${getAssistantAddress()}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            if (_hasAccessAndFloor())
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text('Code d\'accès : ${assistant!.accessCode ?? ''}  étage : ${assistant!.floor ?? ''}', style: const pw.TextStyle(fontSize: 9)),
              ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text('Téléphone : ${getAssistantPhone()}  Courriel : ${getAssistantEmail()}', style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Text(
              '${isAssistantMadame() ? "Agréée" : "Agréé"}, en date du ${getAssistantApprovalDate()}${getAgreementChildrenLine()}  N° agrément : ${getAssistantApprovalNumber()}',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Informe le Président du Conseil Départemental* :', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Text("De l'arrivée de l'enfant le : ", style: const pw.TextStyle(fontSize: 9)),
                pw.Container(width: 80, height: 14, decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)), child: pw.Center(child: pw.Text(fmt(child.contractStartDate), style: const pw.TextStyle(fontSize: 9)))),
                pw.SizedBox(width: 20),
                pw.Text("Du départ de l'enfant le : ", style: const pw.TextStyle(fontSize: 9)),
                pw.Container(width: 80, height: 14, decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)), child: pw.Center(child: pw.Text(child.contractEndDate != null ? fmt(child.contractEndDate!) : '', style: const pw.TextStyle(fontSize: 9)))),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('Nom : ${child.lastName}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Prénom : ${child.firstName}', style: const pw.TextStyle(fontSize: 10)),
            pw.Text('Né le : ${fmt(child.birthDate)}', style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 6),
            pw.Text('Adresse et Tél. des représentants légaux :', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text('Parent 1 : ${child.parents.isNotEmpty ? _parentLine(child.parents.first) : "......................................................"}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Parent 2 : ${child.parents.length > 1 ? _parentLine(child.parents[1]) : "......................................................"}', style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 10),
            pw.Text('Jours et horaires d\'accueil *', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            ..._buildHorairesSectionsDecl(child.weeklyPatterns, child.contractStartDate, fmt, jours),
            pw.SizedBox(height: 8),
            pw.Text(
              'Vacances scolaires :   ${child.vacancesScolaires == true ? "Oui" : child.vacancesScolaires == false ? "Non" : "Oui        Non"}        Particularités d\'accueil / Motifs de départ :',
              style: const pw.TextStyle(fontSize: 8),
            ),
            () {
              final particularitesText = [
                child.particularitesAccueil,
                child.particularitesFinContrat,
              ].whereType<String>().where((s) => s.isNotEmpty).join(' ; ');
              return pw.Container(
                height: 30,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: particularitesText.isNotEmpty
                    ? pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          particularitesText,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      )
                    : pw.LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints?.maxWidth ?? 400;
                          final h = constraints?.maxHeight ?? 30;
                          return pw.CustomPaint(
                            size: PdfPoint(w, h),
                            painter: (PdfGraphics canvas, PdfPoint size) {
                              canvas
                                ..setStrokeColor(PdfColors.black)
                                ..setLineWidth(0.5)
                                ..moveTo(0, 0)
                                ..lineTo(size.x, size.y)
                                ..moveTo(size.x, 0)
                                ..lineTo(0, size.y)
                                ..strokePath();
                            },
                          );
                        },
                      ),
              );
            }(),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Fait à : ', style: const pw.TextStyle(fontSize: 8)),
                pw.Container(width: 90, height: 16, decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)), child: pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2), child: pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text(faitA?.isNotEmpty == true ? faitA! : '', style: const pw.TextStyle(fontSize: 8))))),
                pw.SizedBox(width: 12),
                pw.Text('le ', style: const pw.TextStyle(fontSize: 8)),
                pw.Container(width: 70, height: 16, decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)), child: pw.Center(child: pw.Text(fmt(dateFait), style: const pw.TextStyle(fontSize: 8)))),
                pw.SizedBox(width: 12),
                pw.Text('Signature* ', style: const pw.TextStyle(fontSize: 8)),
                pw.Container(
                  width: 120,
                  height: 36,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                  child: signatureImageBytes != null && signatureImageBytes.isNotEmpty
                      ? pw.Image(
                          pw.MemoryImage(Uint8List.fromList(signatureImageBytes)),
                          width: 120,
                          height: 36,
                          fit: pw.BoxFit.cover,
                        )
                      : pw.SizedBox.shrink(),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text('* Toute modification doit être déclarée dans les 8 jours', style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
            ],
          ),
        );
      },
    ),
  );

  return pdf;
}

/// Construit les sections "Jours et horaires d'accueil" avec historique par période (date de début).
List<pw.Widget> _buildHorairesSectionsDecl(
  List<WeeklyPattern> patterns,
  DateTime contractStartDate,
  String Function(DateTime) fmt,
  List<String> jours,
) {
  if (patterns.isEmpty) {
    return [pw.Table(border: pw.TableBorder.all(width: 0.5), columnWidths: _horairesColumnWidths, children: [])];
  }
  String heureArr(WeeklyPattern pattern, int jour) {
    for (final e in pattern.entries) {
      if (e.weekday == jour) return e.arrivalTime ?? '';
    }
    return '';
  }
  String heureDep(WeeklyPattern pattern, int jour) {
    for (final e in pattern.entries) {
      if (e.weekday == jour) return e.departureTime ?? '';
    }
    return '';
  }

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
    final title = validFrom == null
        ? 'Horaires à compter du ${fmt(effectiveDate)} (début de contrat)'
        : 'Nouveaux horaires à compter du ${fmt(effectiveDate)}';
    out.add(pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
    ));
    out.add(pw.SizedBox(height: 2));
    out.add(pw.Table(
      border: pw.TableBorder.all(width: 0.5),
      columnWidths: _horairesColumnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
            for (var j = 1; j <= 7; j++) pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(jours[j], style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
          ],
        ),
        ..._horairesTableRowsForPatterns(periodPatterns, heureArr, heureDep),
      ],
    ));
  }
  return out;
}

const _horairesColumnWidths = {
  0: pw.FlexColumnWidth(1.5),
  1: pw.FlexColumnWidth(0.7),
  2: pw.FlexColumnWidth(0.7),
  3: pw.FlexColumnWidth(0.7),
  4: pw.FlexColumnWidth(0.7),
  5: pw.FlexColumnWidth(0.7),
  6: pw.FlexColumnWidth(0.7),
  7: pw.FlexColumnWidth(0.7),
};

List<pw.TableRow> _horairesTableRowsForPatterns(
  List<WeeklyPattern> periodPatterns,
  String Function(WeeklyPattern, int) heureArr,
  String Function(WeeklyPattern, int) heureDep,
) {
  if (periodPatterns.isEmpty) return [];
  if (periodPatterns.length == 1) {
    final p = periodPatterns.first;
    return [
      pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text("Heure d'arrivée", style: const pw.TextStyle(fontSize: 7))),
          for (var j = 1; j <= 7; j++) pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(heureArr(p, j), style: const pw.TextStyle(fontSize: 7))),
        ],
      ),
      pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Heure de départ', style: const pw.TextStyle(fontSize: 7))),
          for (var j = 1; j <= 7; j++) pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(heureDep(p, j), style: const pw.TextStyle(fontSize: 7))),
        ],
      ),
    ];
  }
  final rows = <pw.TableRow>[];
  for (var i = 0; i < periodPatterns.length; i++) {
    if (i > 0) {
      rows.add(pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: List.generate(8, (_) => pw.Container(height: 6, alignment: pw.Alignment.center, child: pw.SizedBox.shrink())),
      ));
    }
    final p = periodPatterns[i];
    final label = p.name;
    rows.add(pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('$label - Arrivée', style: const pw.TextStyle(fontSize: 7))),
        for (var j = 1; j <= 7; j++) pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(heureArr(p, j), style: const pw.TextStyle(fontSize: 7))),
      ],
    ));
    rows.add(pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('$label - Départ', style: const pw.TextStyle(fontSize: 7))),
        for (var j = 1; j <= 7; j++) pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(heureDep(p, j), style: const pw.TextStyle(fontSize: 7))),
      ],
    ));
  }
  return rows;
}

String _parentFullAddress(ParentInfo p) {
  final parts = <String>[];
  if (p.address.isNotEmpty) parts.add(p.address);
  if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
  if (p.city != null && p.city!.isNotEmpty) parts.add(p.city!);
  return parts.isEmpty ? '' : parts.join(', ');
}

String _parentLine(ParentInfo p) {
  final parts = <String>[];
  if (p.firstName.isNotEmpty || p.lastName.isNotEmpty) parts.add('${p.firstName} ${p.lastName}');
  final addr = _parentFullAddress(p);
  if (addr.isNotEmpty) parts.add(addr);
  if (p.phone.isNotEmpty) parts.add('Tél. ${p.phone}');
  if (p.email.isNotEmpty) parts.add(p.email);
  return parts.isEmpty ? '' : parts.join(', ');
}
