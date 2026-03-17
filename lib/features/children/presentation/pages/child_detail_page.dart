import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/signature/signature_pad.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/pdf/contract_pdf.dart';
import '../../../../core/pdf/declaration_arrivee_depart_pdf.dart';
import '../../../../core/pdf/diseases_pdf.dart';
import '../../../../core/pdf/medications_pdf.dart';
import '../../../../core/pdf/vaccinations_pdf.dart';
import '../../../../core/photo/photo_helper.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../assistant_profile/presentation/controllers/assistant_profile_controller.dart';
import '../../../diseases/presentation/controllers/disease_controllers.dart';
import '../../../medications/presentation/controllers/medication_controllers.dart';
import '../../../vaccinations/presentation/controllers/vaccination_controllers.dart';
import '../../domain/entities/child.dart';
import '../../domain/entities/parent.dart';
import '../controllers/children_controllers.dart';
import 'pdf_preview_page.dart';

class ChildDetailPage extends ConsumerStatefulWidget {
  const ChildDetailPage({super.key, required this.childId, this.fromArchives = false});

  final int childId;
  /// true si on arrive depuis la liste des archives → pas de modification
  final bool fromArchives;

  @override
  ConsumerState<ChildDetailPage> createState() => _ChildDetailPageState();
}

class _ChildDetailPageState extends ConsumerState<ChildDetailPage> {
  @override
  Widget build(BuildContext context) {
    final asyncChild = ref.watch(childDetailProvider(widget.childId));

    return asyncChild.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Fiche enfant')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Fiche enfant')),
            body: const Center(child: Text('Enfant introuvable')),
          );
        }
        return _buildContent(context, child);
      },
    );
  }

  static String _parentFullAddress(ParentInfo p) {
    final parts = <String>[];
    if (p.address.isNotEmpty) parts.add(p.address);
    if (p.postalCode != null && p.postalCode!.isNotEmpty) parts.add(p.postalCode!);
    if (p.city != null && p.city!.isNotEmpty) parts.add(p.city!);
    return parts.isEmpty ? '' : parts.join(', ');
  }

  Widget _buildContent(BuildContext context, Child child) {
    final isArchived = widget.fromArchives || child.isArchived;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Retour',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.home);
            }
          },
        ),
        title: Text('${child.firstName} ${child.lastName}'),
        actions: [
          if (!isArchived)
            IconButton(
              tooltip: 'Modifier',
              onPressed: () => context.push('/children/${child.id}/edit'),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: buildChildPhotoAvatar(
              context: context,
              photoPath: child.photoPath,
              initial: child.firstName.isNotEmpty
                  ? child.firstName.characters.first
                  : '?',
              radius: 48,
            ),
          ),
          const SizedBox(height: 16),
          if (isArchived)
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.archive, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enfant archivé – les données ne sont pas modifiables.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isArchived) const SizedBox(height: 16),
          if (!isArchived) ...[
            _SectionTitle(title: 'Modules'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ModuleChip(
                  icon: Icons.vaccines,
                  label: 'Vaccinations',
                  onTap: () => context.push('/children/${child.id}/vaccinations'),
                ),
                _ModuleChip(
                  icon: Icons.medication,
                  label: 'Médicaments',
                  onTap: () => context.push('/children/${child.id}/medications'),
                ),
                _ModuleChip(
                  icon: Icons.health_and_safety,
                  label: 'Maladies',
                  onTap: () => context.push('/children/${child.id}/diseases'),
                ),
                _ModuleChip(
                  icon: Icons.medication_liquid,
                  label: 'Doliprane',
                  onTap: () => context.push('/children/${child.id}/doliprane'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Documents'),
            _PdfArchiveButton(
              icon: Icons.assignment,
              title: 'Déclaration arrivée / départ (PDF)',
              onTap: () => _openDeclarationArriveeDepart(context, child),
            ),
            const SizedBox(height: 24),
          ],
          _SectionTitle(title: 'Informations enfant'),
          _InfoRow(
            label: 'Date de naissance',
            value: '${child.birthDate.day.toString().padLeft(2, '0')}/'
                '${child.birthDate.month.toString().padLeft(2, '0')}/'
                '${child.birthDate.year}',
          ),
          _InfoRow(
            label: 'Début de contrat',
            value: '${child.contractStartDate.day.toString().padLeft(2, '0')}/'
                '${child.contractStartDate.month.toString().padLeft(2, '0')}/'
                '${child.contractStartDate.year}',
          ),
          if (child.contractEndDate != null)
            _InfoRow(
              label: 'Fin de contrat',
              value: '${child.contractEndDate!.day.toString().padLeft(2, '0')}/'
                  '${child.contractEndDate!.month.toString().padLeft(2, '0')}/'
                  '${child.contractEndDate!.year}',
            ),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Parents'),
          if (child.parents.isNotEmpty) ...[
            for (final p in child.parents) ...[
              Text(
                p.role == 'parent1' ? 'Parent 1' : 'Parent 2',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              _InfoRow(label: 'Nom', value: '${p.firstName} ${p.lastName}'),
              _InfoRow(label: 'Adresse', value: _parentFullAddress(p)),
              if (p.phone.isNotEmpty) _InfoRow(label: 'Téléphone', value: p.phone),
              if (p.email.isNotEmpty) _InfoRow(label: 'Email', value: p.email),
              const SizedBox(height: 8),
            ],
          ] else
            const Text('Aucune information parent renseignée.'),
          const SizedBox(height: 16),
          _SectionTitle(title: 'Horaires'),
          if (child.weeklyPatterns.isNotEmpty) ...[
            ...() {
              final currentPatterns = child.weeklyPatterns.where((p) => p.validUntil == null).toList();
              if (currentPatterns.isEmpty) return [const Text('Aucun horaire courant.')];
              return [
                for (final pattern in currentPatterns) ...[
                  Text(
                    pattern.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...pattern.entries.map(
                    (e) => _InfoRow(
                      label: _weekdayLabel(e.weekday),
                      value: '${e.arrivalTime ?? '–'} → ${e.departureTime ?? '–'}',
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ];
            }(),
            if (!isArchived) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/children/${child.id}/schedule-change', extra: child),
                icon: const Icon(Icons.schedule),
                label: const Text('Modifier les horaires (nouveaux à compter du…)'),
              ),
            ],
          ] else
            const Text('Aucun horaire renseigné.'),
          const SizedBox(height: 24),
          if (isArchived) ...[
            _SectionTitle(title: 'PDF d\'archivage'),
            _PdfArchiveButton(
              icon: Icons.description,
              title: 'Fiche enfant',
              onTap: () => _openPdf(context, child, 'fiche_enfant', () => buildContractPdf(child)),
            ),
            const SizedBox(height: 8),
            _PdfArchiveButton(
              icon: Icons.assignment,
              title: 'Déclaration arrivée / départ',
              onTap: () => _openDeclarationArriveeDepartArchived(context, child),
            ),
            const SizedBox(height: 8),
            _PdfArchiveButton(
              icon: Icons.vaccines,
              title: 'Vaccinations',
              onTap: () => _openVaccinationsPdf(context, child),
            ),
            const SizedBox(height: 8),
            _PdfArchiveButton(
              icon: Icons.medication,
              title: 'Médicaments',
              onTap: () => _openMedicationsPdf(context, child),
            ),
            const SizedBox(height: 8),
            _PdfArchiveButton(
              icon: Icons.health_and_safety,
              title: 'Maladies',
              onTap: () => _openDiseasesPdf(context, child),
            ),
          ],
          if (!child.isArchived) ...[
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _onArchive(context, child),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archiver cet enfant'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi'];
    return weekday >= 1 && weekday <= 5 ? labels[weekday] : 'Jour $weekday';
  }

  Future<void> _openDeclarationArriveeDepart(BuildContext context, Child child) async {
    final assistant = ref.read(assistantProfileControllerProvider).value?.assistant;
    // Étape 1 : Fait à + Date
    final step1 = await showDialog<({String faitA, DateTime date})>(
      context: context,
      builder: (ctx) {
        final faitACtrl = TextEditingController(text: 'Andrésy');
        final date = ValueNotifier<DateTime>(DateTime.now());
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Déclaration arrivée / départ'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Lieu et date :', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: faitACtrl,
                    decoration: const InputDecoration(
                      labelText: 'Fait à (lieu)',
                      hintText: 'Ex. : Versailles',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<DateTime>(
                    valueListenable: date,
                    builder: (context, d, _) {
                      final fmt = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                      return InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: d,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) date.value = picked;
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(fmt),
                        ),
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop((faitA: faitACtrl.text.trim(), date: date.value)),
                  child: const Text('Suivant – Signer'),
                ),
              ],
            );
          },
        );
      },
    );
    if (step1 == null || !context.mounted) return;
    // Étape 2 : signature (utiliser celle du profil si enregistrée, sinon afficher le pad)
    Uint8List? signatureBytes;
    if (assistant?.signaturePath != null) {
      signatureBytes = await loadAssistantSignatureBytes(assistant!.signaturePath);
    }
    if (signatureBytes == null) {
      final signatureKey = GlobalKey();
      final _signatureCancelled = Object();
      final signatureResult = await showDialog<Object?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Signature'),
          content: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Signez dans le cadre (clic maintenu + glisser). Sur Mac, si le pad ne réagit pas : utilisez « Sans signature » puis signez à la main sur l’impression.', style: TextStyle(fontSize: 11)),
                const SizedBox(height: 12),
                SignaturePad(repaintBoundaryKey: signatureKey, height: 160),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(_signatureCancelled), child: const Text('Retour')),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Sans signature'),
            ),
            FilledButton(
              onPressed: () async {
                ui.Image? image;
                try {
                  image = await SignaturePad.capture(signatureKey);
                } catch (_) {}
                Uint8List? bytes;
                if (image != null) {
                  final list = await SignaturePad.imageToPngBytes(image);
                  if (list != null) bytes = Uint8List.fromList(list);
                }
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop(bytes);
              },
              child: const Text('Générer le PDF'),
            ),
          ],
        );
      },
    );
      if (!context.mounted || identical(signatureResult, _signatureCancelled)) return;
      signatureBytes = signatureResult as Uint8List?;
    }
    Uint8List? logoBytes;
    for (final path in ['assets/images/logo_yvelines.png', 'assets/images/LOGO_yvelines.png']) {
      try {
        final data = await rootBundle.load(path);
        logoBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        break;
      } catch (_) {}
    }
    try {
      final doc = await buildDeclarationArriveeDepartPdf(
        child: child,
        assistant: assistant,
        faitA: step1.faitA.isEmpty ? null : step1.faitA,
        date: step1.date,
        signatureImageBytes: signatureBytes,
        logoImageBytes: logoBytes,
      );
      final Uint8List bytes = await doc.save();
      if (!context.mounted) return;
      context.push(RoutePaths.pdfPreview, extra: PdfPreviewArgs(bytes: bytes, filename: 'declaration_arrivee_depart_${child.lastName}_${child.firstName}.pdf'));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  /// Version archivage : lieu/date figés, signature optionnelle (possible à la main après impression).
  Future<void> _openDeclarationArriveeDepartArchived(BuildContext context, Child child) async {
    final assistant = ref.read(assistantProfileControllerProvider).value?.assistant;
    final faitA = 'Andrésy';
    final date = child.contractEndDate ?? DateTime.now();

    Uint8List? signatureResult;
    if (child.archiveSignaturePath != null) {
      signatureResult = await loadAssistantSignatureBytes(child.archiveSignaturePath);
    }
    if ((signatureResult == null || signatureResult.isEmpty) && assistant?.signaturePath != null) {
      signatureResult = await loadAssistantSignatureBytes(assistant!.signaturePath);
    }
    if (signatureResult == null || signatureResult.isEmpty) {
      final signatureKey = GlobalKey();
      signatureResult = await showDialog<Uint8List?>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Signature'),
            content: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Signez dans le cadre ci-dessous, ou générez sans signature pour signer à la main après impression.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SignaturePad(repaintBoundaryKey: signatureKey, height: 160),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Sans signature'),
              ),
              FilledButton(
                onPressed: () async {
                  ui.Image? image;
                  try {
                    image = await SignaturePad.capture(signatureKey);
                  } catch (_) {}
                  Uint8List? bytes;
                  if (image != null) {
                    final list = await SignaturePad.imageToPngBytes(image);
                    if (list != null && list.isNotEmpty) bytes = Uint8List.fromList(list);
                  }
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop(bytes);
                },
                child: const Text('Générer le PDF'),
              ),
            ],
          );
        },
      );
    }

    if (!context.mounted) return;

    Uint8List? logoBytes;
    for (final path in ['assets/images/logo_yvelines.png', 'assets/images/LOGO_yvelines.png']) {
      try {
        final data = await rootBundle.load(path);
        logoBytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        break;
      } catch (_) {}
    }

    try {
      final doc = await buildDeclarationArriveeDepartPdf(
        child: child,
        assistant: assistant,
        faitA: faitA,
        date: date,
        signatureImageBytes: signatureResult,
        logoImageBytes: logoBytes,
      );
      final Uint8List bytes = await doc.save();
      if (!context.mounted) return;
      context.push(
        RoutePaths.pdfPreview,
        extra: PdfPreviewArgs(
          bytes: bytes,
          filename: 'declaration_arrivee_depart_${child.lastName}_${child.firstName}.pdf',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _openPdf(
    BuildContext context,
    Child child,
    String filename,
    Future<dynamic> Function() buildPdf,
  ) async {
    try {
      final doc = await buildPdf();
      final Uint8List bytes = await doc.save();
      if (!context.mounted) return;
      context.push(RoutePaths.pdfPreview, extra: PdfPreviewArgs(bytes: bytes, filename: '$filename.pdf'));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _openVaccinationsPdf(BuildContext context, Child child) async {
    final schedule = await ref.read(getVaccinationScheduleProvider).call(child.id, child.birthDate, vaccinationScheme: child.vaccinationScheme);
    if (!context.mounted) return;
    final photoBytes = await Future.wait(
      schedule.map((e) async {
        if (e.justificationPhotoPath == null || e.justificationPhotoPath!.isEmpty) return null;
        return loadJustificationPhotoBytes(e.justificationPhotoPath!);
      }),
    );
    if (!context.mounted) return;
    await _openPdf(context, child, 'vaccinations', () => buildVaccinationsPdfFromEntries(child, schedule, justificationPhotoBytes: photoBytes));
  }

  Future<void> _openMedicationsPdf(BuildContext context, Child child) async {
    final entries = await ref.read(getMedicationsForChildProvider).call(child.id);
    if (!context.mounted) return;
    await _openPdf(context, child, 'medicaments', () => buildMedicationsPdfFromEntries(child, entries));
  }

  Future<void> _openDiseasesPdf(BuildContext context, Child child) async {
    final entries = await ref.read(getDiseasesForChildProvider).call(child.id);
    if (!context.mounted) return;
    await _openPdf(context, child, 'maladies', () => buildDiseasesPdfFromEntries(child, entries));
  }

  Future<void> _onArchive(BuildContext context, Child child) async {
    final result = await showDialog<({DateTime endDate, String? motif, Uint8List? signatureBytes})?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ArchiveDialogContent(
        child: child,
        onCancel: () => Navigator.pop(ctx, null),
        onConfirm: (endDate, motif, signatureBytes) => Navigator.pop(ctx, (endDate: endDate, motif: motif, signatureBytes: signatureBytes)),
      ),
    );
    if (result == null || !context.mounted) return;

    String? path;
    if (result.signatureBytes != null && result.signatureBytes!.isNotEmpty) {
      path = await saveArchiveSignature(child.id, result.signatureBytes!);
    }
    try {
      await ref.read(archiveChildProvider).call(
        child.id,
        contractEndDate: result.endDate,
        particularitesFinContrat: result.motif,
        archiveSignaturePath: path,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'archivage : $e')),
      );
      return;
    }
    if (!mounted) return;
    ref.invalidate(activeChildrenControllerProvider);
    ref.invalidate(archivedChildrenControllerProvider);
    ref.invalidate(childDetailProvider(child.id));

    if (!mounted) return;
    if (!context.mounted) return;
    context.go(RoutePaths.home);
    if (!context.mounted) return;
    context.push('/children/${child.id}/archive-pdfs');
  }
}

class _ArchiveDialogContent extends StatefulWidget {
  const _ArchiveDialogContent({
    required this.child,
    required this.onCancel,
    required this.onConfirm,
  });

  final Child child;
  final VoidCallback onCancel;
  final void Function(DateTime endDate, String? motif, Uint8List? signatureBytes) onConfirm;

  @override
  State<_ArchiveDialogContent> createState() => _ArchiveDialogContentState();
}

class _ArchiveDialogContentState extends State<_ArchiveDialogContent> {
  final _motifCtrl = TextEditingController();
  final _signatureKey = GlobalKey();

  DateTime? _endDate;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _endDate = widget.child.contractEndDate;
  }

  @override
  void dispose() {
    _motifCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = _endDate == null
        ? 'Choisir la date'
        : '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}';

    return AlertDialog(
      title: const Text('Archiver cet enfant'),
      content: SingleChildScrollView(
        physics: _isSigning ? const NeverScrollableScrollPhysics() : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Saisir les informations lors de l\'archivage. Après archivage, les données ne sont plus modifiables.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            const Text('Date de fin de contrat *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final first = widget.child.contractStartDate;
                final initial = _endDate ?? (now.isBefore(first) ? first : now);
                final last = (initial.isBefore(now) ? now : initial).add(const Duration(days: 365));
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: first,
                  lastDate: last,
                  helpText: 'Date de fin de contrat',
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(dateFmt),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Raison / motif de fin de contrat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _motifCtrl,
              decoration: const InputDecoration(
                hintText: 'Optionnel',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Signature (optionnel)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Vous pouvez signer ici, ou à la main après impression.', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Listener(
              onPointerDown: (_) => setState(() => _isSigning = true),
              onPointerUp: (_) => setState(() => _isSigning = false),
              onPointerCancel: (_) => setState(() => _isSigning = false),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SignaturePad(repaintBoundaryKey: _signatureKey, height: 140),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () async {
            if (_endDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez choisir la date de fin de contrat.')),
              );
              return;
            }
            ui.Image? image;
            try {
              image = await SignaturePad.capture(_signatureKey);
            } catch (_) {}
            Uint8List? bytes;
            if (image != null) {
              final list = await SignaturePad.imageToPngBytes(image);
              if (list != null && list.isNotEmpty) bytes = Uint8List.fromList(list);
            }
            final motif = _motifCtrl.text.trim();
            widget.onConfirm(_endDate!, motif.isEmpty ? null : motif, bytes);
          },
          child: const Text('Archiver'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _PdfArchiveButton extends StatelessWidget {
  const _PdfArchiveButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.picture_as_pdf),
        onTap: onTap,
      ),
    );
  }
}
