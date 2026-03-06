import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/pdf/contract_pdf.dart';
import '../../../../core/pdf/declaration_arrivee_depart_pdf.dart';
import '../../../../core/pdf/diseases_pdf.dart';
import '../../../../core/pdf/medications_pdf.dart';
import '../../../../core/pdf/vaccinations_pdf.dart';
import '../../../../core/photo/photo_helper.dart';
import '../../../../core/routing/route_paths.dart';
import 'pdf_preview_page.dart';
import '../../../assistant_profile/presentation/controllers/assistant_profile_controller.dart';
import '../../../diseases/presentation/controllers/disease_controllers.dart';
import '../../../medications/presentation/controllers/medication_controllers.dart';
import '../../../vaccinations/presentation/controllers/vaccination_controllers.dart';
import '../../domain/entities/child.dart';
import '../controllers/children_controllers.dart';

class ArchivePdfsPage extends ConsumerWidget {
  const ArchivePdfsPage({super.key, required this.childId});

  final int childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChild = ref.watch(childDetailProvider(childId));

    return asyncChild.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('PDF récapitulatifs')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('PDF récapitulatifs')),
            body: const Center(child: Text('Enfant introuvable')),
          );
        }
        return _buildContent(context, ref, child);
      },
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Child child) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générer les PDF'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go(RoutePaths.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Choisir le récapitulatif à imprimer ou enregistrer :',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          _PdfButton(
            icon: Icons.assignment,
            title: 'Déclaration arrivée / départ',
            subtitle: 'Document non modifiable (lieu et date figés)',
            onTap: () => _generateDeclarationArriveeDepart(context, ref, child),
          ),
          const SizedBox(height: 12),
          _PdfButton(
            icon: Icons.description,
            title: 'Fiche enfant',
            subtitle: 'Infos enfant, parents, horaires',
            onTap: () => _generateAndShow(context, 'fiche_enfant', () => buildContractPdf(child)),
          ),
          const SizedBox(height: 12),
          _PdfButton(
            icon: Icons.vaccines,
            title: 'Vaccinations',
            subtitle: 'Tableau des vaccins',
            onTap: () async {
              final schedule = await ref.read(getVaccinationScheduleProvider).call(child.id, child.birthDate, vaccinationScheme: child.vaccinationScheme);
              if (!context.mounted) return;
              final photoBytes = await Future.wait(
                schedule.map((e) async {
                  if (e.justificationPhotoPath == null || e.justificationPhotoPath!.isEmpty) return null;
                  return loadJustificationPhotoBytes(e.justificationPhotoPath!);
                }),
              );
              if (!context.mounted) return;
              await _generateAndShow(context, 'vaccinations', () => buildVaccinationsPdfFromEntries(child, schedule, justificationPhotoBytes: photoBytes));
            },
          ),
          const SizedBox(height: 12),
          _PdfButton(
            icon: Icons.medication,
            title: 'Médicaments',
            subtitle: 'Historique des prises',
            onTap: () async {
              final entries = await ref.read(getMedicationsForChildProvider).call(child.id);
              if (!context.mounted) return;
              await _generateAndShow(context, 'medicaments', () => buildMedicationsPdfFromEntries(child, entries));
            },
          ),
          const SizedBox(height: 12),
          _PdfButton(
            icon: Icons.health_and_safety,
            title: 'Maladies',
            subtitle: 'Historique des maladies',
            onTap: () async {
              final entries = await ref.read(getDiseasesForChildProvider).call(child.id);
              if (!context.mounted) return;
              await _generateAndShow(context, 'maladies', () => buildDiseasesPdfFromEntries(child, entries));
            },
          ),
        ],
      ),
    );
  }
}

class _PdfButton extends StatelessWidget {
  const _PdfButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.picture_as_pdf),
        onTap: onTap,
      ),
    );
  }
}

/// Génère le PDF Déclaration arrivée/départ (version archivage : non modifiable, lieu et date figés).
Future<void> _generateDeclarationArriveeDepart(BuildContext context, WidgetRef ref, Child child) async {
  try {
    final assistant = ref.read(assistantProfileControllerProvider).value?.assistant;
    Uint8List? signatureBytes;
    if (child.archiveSignaturePath != null) {
      signatureBytes = await loadAssistantSignatureBytes(child.archiveSignaturePath);
    }
    if ((signatureBytes == null || signatureBytes.isEmpty) && assistant?.signaturePath != null) {
      signatureBytes = await loadAssistantSignatureBytes(assistant!.signaturePath);
    }
    final faitA = 'Andrésy';
    final date = child.contractEndDate ?? DateTime.now();

    Uint8List? logoBytes;
    for (final path in ['assets/images/logo_yvelines.png', 'assets/images/LOGO_yvelines.png']) {
      try {
        final data = await rootBundle.load(path);
        logoBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        break;
      } catch (_) {}
    }

    final doc = await buildDeclarationArriveeDepartPdf(
      child: child,
      assistant: assistant,
      faitA: faitA,
      date: date,
      signatureImageBytes: signatureBytes?.isNotEmpty == true ? signatureBytes : null,
      logoImageBytes: logoBytes,
    );
    final Uint8List bytes = await doc.save();
    if (!context.mounted) return;
    final filename = 'declaration_arrivee_depart_${child.lastName}_${child.firstName}.pdf';
    context.push(RoutePaths.pdfPreview, extra: PdfPreviewArgs(bytes: bytes, filename: filename));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }
}

Future<void> _generateAndShow(
  BuildContext context,
  String baseName,
  Future<dynamic> Function() buildPdf,
) async {
  try {
    final doc = await buildPdf();
    final Uint8List bytes = await doc.save();
    if (!context.mounted) return;
    final filename = '$baseName.pdf';
    context.push(RoutePaths.pdfPreview, extra: PdfPreviewArgs(bytes: bytes, filename: filename));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }
}
