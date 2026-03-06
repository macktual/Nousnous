import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/pdf/medications_pdf.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../children/presentation/pages/pdf_preview_page.dart';
import '../../../children/domain/entities/child.dart';
import '../../../children/presentation/controllers/children_controllers.dart';
import '../../domain/entities/medication_entry.dart';
import '../controllers/medication_controllers.dart';

class MedicationsPage extends ConsumerWidget {
  const MedicationsPage({super.key, required this.childId});

  final int childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChild = ref.watch(childDetailProvider(childId));

    return asyncChild.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Médicaments')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Médicaments')),
            body: const Center(child: Text('Enfant introuvable')),
          );
        }
        return _MedicationsBody(child: child);
      },
    );
  }
}

class _MedicationsBody extends ConsumerWidget {
  const _MedicationsBody({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medications = ref.watch(medicationsListProvider(child.id));
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Médicaments – ${child.firstName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Générer le PDF',
            onPressed: () => _generatePdf(context, ref),
          ),
        ],
      ),
      body: medications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_liquid, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('Aucune prise enregistrée.'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/children/${child.id}/medications/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une prise'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              return _MedicationCard(
                entry: e,
                dateFormat: dateFormat,
                onTap: () => context.push('/children/${child.id}/medications/edit/${e.id}'),
                onDelete: () => _confirmDelete(context, ref, e),
              );
            },
          );
        },
      ),
      floatingActionButton: medications.hasValue && medications.value!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/children/${child.id}/medications/new'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _generatePdf(BuildContext context, WidgetRef ref) async {
    final entries = await ref.read(getMedicationsForChildProvider).call(child.id);
    if (!context.mounted) return;
    final doc = await buildMedicationsPdfFromEntries(child, entries);
    final bytes = await doc.save();
    if (!context.mounted) return;
    context.push(RoutePaths.pdfPreview, extra: PdfPreviewArgs(bytes: bytes, filename: 'medicaments.pdf'));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, MedicationEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text(
          'Supprimer la prise du ${DateFormat('dd/MM/yyyy').format(entry.dateTime)} – ${entry.medicationName} ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(deleteMedicationProvider).call(entry.id);
      ref.invalidate(medicationsListProvider(child.id));
    }
  }
}

class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.entry,
    required this.dateFormat,
    required this.onTap,
    required this.onDelete,
  });

  final MedicationEntry entry;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(Icons.medication, color: Theme.of(context).colorScheme.onPrimaryContainer),
        ),
        title: Text(entry.medicationName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(entry.dateTime)),
            if (entry.posology != null && entry.posology!.isNotEmpty)
              Text('Posologie : ${entry.posology!}', style: Theme.of(context).textTheme.bodySmall),
            if (entry.reason != null && entry.reason!.isNotEmpty)
              Text('Motif : ${entry.reason!}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: 'Supprimer',
        ),
      ),
    );
  }
}
