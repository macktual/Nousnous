import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/photo/photo_helper.dart';
import '../../../../core/pdf/vaccinations_pdf.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../children/domain/entities/child.dart';
import '../../../children/presentation/pages/pdf_preview_page.dart';
import '../../../children/presentation/controllers/children_controllers.dart';
import '../../domain/entities/vaccination_entry.dart';
import '../controllers/vaccination_controllers.dart';

class VaccinationsPage extends ConsumerWidget {
  const VaccinationsPage({super.key, required this.childId});

  final int childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChild = ref.watch(childDetailProvider(childId));

    return asyncChild.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Vaccinations')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vaccinations')),
            body: const Center(child: Text('Enfant introuvable')),
          );
        }
        return _VaccinationsBody(child: child);
      },
    );
  }
}

class _VaccinationsBody extends ConsumerStatefulWidget {
  const _VaccinationsBody({required this.child});

  final Child child;

  @override
  ConsumerState<_VaccinationsBody> createState() => _VaccinationsBodyState();
}

class _VaccinationsBodyState extends ConsumerState<_VaccinationsBody> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(vaccinationScheduleProvider((
      childId: widget.child.id,
      birthDate: widget.child.birthDate,
      vaccinationScheme: widget.child.vaccinationScheme,
    )));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Vaccinations – ${widget.child.firstName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Générer le PDF',
            onPressed: () => _generatePdf(context),
          ),
        ],
      ),
      body: schedule.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text('Aucune vaccination dans la liste. Ajoutez des vaccins dans « Mettre à jour la liste ».'),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _VaccinationSchemeSelector(
                currentScheme: widget.child.vaccinationScheme,
                onSchemeChanged: (scheme) => _setVaccinationScheme(context, scheme),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push('/vaccination-rules'),
                icon: const Icon(Icons.settings),
                label: const Text('Mettre à jour la liste des vaccins'),
              ),
              const SizedBox(height: 16),
              ...entries.map((e) => _VaccinationRow(
                    entry: e,
                    dateFormat: _dateFormat,
                    onToggle: (done) => _onToggle(context, done, e),
                    onActualDateTap: () => _pickActualDate(context, e),
                    onEditJustification: (entry) => _showEditJustificationDialog(context, entry),
                    onAddPhoto: (entry) => _addJustificationPhoto(context, entry),
                    onRemovePhoto: (entry) => _setJustification(entry, clearPhoto: true),
                    onShowPhoto: (path) => showJustificationPhotoViewer(context, path),
                  )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onToggle(BuildContext context, bool done, VaccinationEntry e) async {
    if (done) {
      final date = await showDatePicker(
        context: context,
        initialDate: e.actualDate ?? DateTime.now(),
        firstDate: widget.child.birthDate,
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (date == null) return;
      await ref.read(updateVaccinationStatusProvider).setDone(
            widget.child.id,
            e.rule.id,
            actualDate: date,
          );
    } else {
      await ref.read(updateVaccinationStatusProvider).setUndone(
            widget.child.id,
            e.rule.id,
          );
    }
    ref.invalidate(vaccinationScheduleProvider((
      childId: widget.child.id,
      birthDate: widget.child.birthDate,
      vaccinationScheme: widget.child.vaccinationScheme,
    )));
  }

  Future<void> _pickActualDate(BuildContext context, VaccinationEntry e) async {
    final date = await showDatePicker(
      context: context,
      initialDate: e.actualDate ?? e.theoreticalDate,
      firstDate: widget.child.birthDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    await ref.read(updateVaccinationStatusProvider).setDone(
          widget.child.id,
          e.rule.id,
          actualDate: date,
        );
    ref.invalidate(vaccinationScheduleProvider((
      childId: widget.child.id,
      birthDate: widget.child.birthDate,
      vaccinationScheme: widget.child.vaccinationScheme,
    )));
  }

  Future<void> _setJustification(VaccinationEntry e, {
    String? justificationSource,
    DateTime? justificationDate,
    String? justificationPhotoPath,
    bool clearPhoto = false,
  }) async {
    await ref.read(updateVaccinationStatusProvider).setJustification(
          widget.child.id,
          e.rule.id,
          justificationSource: justificationSource ?? e.justificationSource,
          justificationDate: justificationDate ?? e.justificationDate,
          justificationPhotoPath: clearPhoto ? null : (justificationPhotoPath ?? e.justificationPhotoPath),
        );
    ref.invalidate(vaccinationScheduleProvider((
      childId: widget.child.id,
      birthDate: widget.child.birthDate,
      vaccinationScheme: widget.child.vaccinationScheme,
    )));
  }

  Future<void> _showEditJustificationDialog(BuildContext context, VaccinationEntry e) async {
    final sourceCtrl = TextEditingController(text: e.justificationSource ?? '');
    DateTime? pickedDate = e.justificationDate;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Source et date du justificatif'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: sourceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      hintText: 'ex: WhatsApp, email, papier',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: pickedDate ?? DateTime.now(),
                        firstDate: widget.child.birthDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => pickedDate = date);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        pickedDate != null ? _dateFormat.format(pickedDate!) : 'Appuyer pour choisir',
                        style: TextStyle(
                          color: pickedDate != null ? null : Theme.of(ctx).hintColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );
    if (result == true && context.mounted) {
      final source = sourceCtrl.text.trim();
      // Enregistrement explicite source + date (permet de vider la source si l'utilisateur efface).
      await ref.read(updateVaccinationStatusProvider).setJustification(
            widget.child.id,
            e.rule.id,
            justificationSource: source.isEmpty ? null : source,
            justificationDate: pickedDate,
            justificationPhotoPath: e.justificationPhotoPath,
          );
      ref.invalidate(vaccinationScheduleProvider((
        childId: widget.child.id,
        birthDate: widget.child.birthDate,
        vaccinationScheme: widget.child.vaccinationScheme,
      )));
    }
  }

  Future<void> _setVaccinationScheme(BuildContext context, String scheme) async {
    final updated = widget.child.copyWith(vaccinationScheme: scheme);
    await ref.read(updateChildProvider).call(updated);
    ref.invalidate(childDetailProvider(widget.child.id));
    ref.invalidate(vaccinationScheduleProvider((
      childId: widget.child.id,
      birthDate: widget.child.birthDate,
      vaccinationScheme: scheme,
    )));
  }

  Future<void> _addJustificationPhoto(BuildContext context, VaccinationEntry e) async {
    if (!isPhotoSupported) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Appareil photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 75);
      if (xFile == null || !context.mounted) return;
      final path = await saveVaccinationJustificationPhoto(
        xFile,
        childId: widget.child.id,
        ruleId: e.rule.id,
      );
      if (path != null && context.mounted) await _setJustification(e, justificationPhotoPath: path);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir l\'appareil photo ou la galerie. Vérifiez les autorisations.')),
        );
      }
    }
  }

  Future<void> _generatePdf(BuildContext context) async {
    final schedule = await ref.read(getVaccinationScheduleProvider).call(
          widget.child.id,
          widget.child.birthDate,
        );
    final photoBytes = await Future.wait(
      schedule.map((e) async {
        if (e.justificationPhotoPath == null || e.justificationPhotoPath!.isEmpty) return null;
        return loadJustificationPhotoBytes(e.justificationPhotoPath!);
      }),
    );
    final doc = await buildVaccinationsPdfFromEntries(
      widget.child,
      schedule,
      justificationPhotoBytes: photoBytes,
    );
    final bytes = await doc.save();
    if (!context.mounted) return;
    context.push(RoutePaths.pdfPreview, extra: PdfPreviewArgs(bytes: bytes, filename: 'vaccinations.pdf'));
  }
}

/// Sélecteur du schéma vaccinal DTP/Hib/Hépatite B (choix du médecin).
/// Affichage sur plusieurs lignes / pleine largeur pour être lisible sur smartphone.
class _VaccinationSchemeSelector extends StatelessWidget {
  const _VaccinationSchemeSelector({
    required this.currentScheme,
    required this.onSchemeChanged,
  });

  final String? currentScheme;
  final void Function(String scheme) onSchemeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Schéma vaccinal (selon le médecin)',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _SchemeOption(
              label: 'Hexavalent (INFANRIX HEXA®, Hexyon®, Vaxelis®)',
              selected: currentScheme == 'hexavalent',
              onTap: () => onSchemeChanged('hexavalent'),
            ),
            const SizedBox(height: 6),
            _SchemeOption(
              label: 'Séparé (Hib Infanrixquinta®/Pentavac® + Hépatite B Engerix®/HBVAXPRO®)',
              selected: currentScheme == 'separate',
              onTap: () => onSchemeChanged('separate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchemeOption extends StatelessWidget {
  const _SchemeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 22,
                color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                  ),
                  softWrap: true,
                  maxLines: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _justificationSummary(VaccinationEntry entry, DateFormat dateFormat) {
  final hasSource = entry.justificationSource != null && entry.justificationSource!.trim().isNotEmpty;
  final hasDate = entry.justificationDate != null;
  if (!hasSource && !hasDate) return 'Source et date (appuyer pour renseigner)';
  final parts = <String>[];
  if (hasSource) parts.add('Source : ${entry.justificationSource!.trim()}');
  if (hasDate) parts.add('Date : ${dateFormat.format(entry.justificationDate!)}');
  return parts.join(' · ');
}

class _VaccinationRow extends StatelessWidget {
  const _VaccinationRow({
    required this.entry,
    required this.dateFormat,
    required this.onToggle,
    required this.onActualDateTap,
    required this.onEditJustification,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onShowPhoto,
  });

  final VaccinationEntry entry;
  final DateFormat dateFormat;
  final void Function(bool done) onToggle;
  final VoidCallback onActualDateTap;
  final void Function(VaccinationEntry entry) onEditJustification;
  final void Function(VaccinationEntry entry) onAddPhoto;
  final void Function(VaccinationEntry entry) onRemovePhoto;
  final void Function(String photoPath) onShowPhoto;

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        !entry.isDone && entry.theoreticalDate.isBefore(DateTime.now());
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? theme.colorScheme.errorContainer.withValues(alpha: 0.3) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: entry.isDone,
              onChanged: (v) => onToggle(v ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.rule.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date théorique : ${dateFormat.format(entry.theoreticalDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (entry.isDone) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onActualDateTap,
                      child: Text(
                        entry.actualDate != null
                            ? 'Date réelle : ${dateFormat.format(entry.actualDate!)} (appuyer pour modifier)'
                            : 'Date réelle : (appuyer pour saisir)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Justificatif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => onEditJustification(entry),
                      child: Row(
                        children: [
                          Icon(Icons.edit_note, size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _justificationSummary(entry, dateFormat),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isPhotoSupported) ...[
                      if (entry.justificationPhotoPath != null &&
                          entry.justificationPhotoPath!.isNotEmpty) ...[
                        Row(
                          children: [
                            InkWell(
                              onTap: () => onShowPhoto(entry.justificationPhotoPath!),
                              borderRadius: BorderRadius.circular(8),
                              child: buildJustificationPhotoThumbnail(entry.justificationPhotoPath!),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => onAddPhoto(entry),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Changer'),
                            ),
                            TextButton.icon(
                              onPressed: () => onRemovePhoto(entry),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      ] else
                        OutlinedButton.icon(
                          onPressed: () => onAddPhoto(entry),
                          icon: const Icon(Icons.add_photo_alternate, size: 20),
                          label: const Text('Photo (reçu du parent)'),
                        ),
                    ],
                  ],
                  if (isOverdue)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'En retard',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
