import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/notifications/doliprane_notification_service.dart';
import '../../../../core/photo/photo_helper.dart';
import '../../../children/domain/entities/child.dart';
import '../../../children/presentation/controllers/children_controllers.dart';
import '../../domain/entities/doliprane_prescription.dart';
import '../controllers/doliprane_controllers.dart';

class DolipranePage extends ConsumerWidget {
  const DolipranePage({super.key, required this.childId});

  final int childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChild = ref.watch(childDetailProvider(childId));

    return asyncChild.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Doliprane')),
        body: Center(child: Text('Erreur : $e')),
      ),
      data: (child) {
        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Doliprane')),
            body: const Center(child: Text('Enfant introuvable')),
          );
        }
        return _DolipraneBody(child: child);
      },
    );
  }
}

class _DolipraneBody extends ConsumerWidget {
  const _DolipraneBody({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptions = ref.watch(dolipraneListProvider(child.id));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Doliprane – ${child.firstName}'),
      ),
      body: prescriptions.when(
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
                  const Text('Aucune ordonnance Doliprane enregistrée.'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/children/${child.id}/doliprane/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter une ordonnance'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final p = entries[index];
              return _PrescriptionCard(
                prescription: p,
                dateFormat: dateFormat,
                onTap: () => context.push('/children/${child.id}/doliprane/edit/${p.id}', extra: p),
                onDelete: () => _confirmDelete(context, ref, p),
              );
            },
          );
        },
      ),
      floatingActionButton: prescriptions.hasValue && prescriptions.value!.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => context.push('/children/${child.id}/doliprane/new'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, DolipranePrescription p) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Supprimer l\'ordonnance (fin le ${DateFormat('dd/MM/yyyy').format(p.endDate)}) ?',
                textAlign: TextAlign.center,
                style: Theme.of(ctx).textTheme.bodyLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Annuler'),
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text('Supprimer', style: TextStyle(color: Theme.of(ctx).colorScheme.error, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.of(ctx).pop(true),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await DolipraneNotificationService.cancelReminder(p.id);
      } catch (_) {}
      await ref.read(deleteDolipranePrescriptionProvider).call(p.id);
      ref.invalidate(dolipraneListProvider(child.id));
    }
  }
}

class _PrescriptionCard extends StatelessWidget {
  const _PrescriptionCard({
    required this.prescription,
    required this.dateFormat,
    required this.onTap,
    required this.onDelete,
  });

  final DolipranePrescription prescription;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final reminder = prescription.reminderDate != null
        ? 'Rappel : ${dateFormat.format(prescription.reminderDate!)} (${prescription.reminderWeeksBeforeEnd} sem. avant fin)'
        : null;
    final isReminderSoon = prescription.reminderDate != null &&
        !prescription.isReminderPassed &&
        prescription.reminderDate!.difference(DateTime.now()).inDays <= 7;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prescription.photoPath != null && prescription.photoPath!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: buildJustificationPhotoThumbnail(prescription.photoPath!, size: 48),
                      ),
                    Text(
                      'Fin : ${dateFormat.format(prescription.endDate)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (prescription.childWeightKg != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Poids : ${prescription.childWeightKg} kg'
                            '${prescription.weightDate != null ? ' (${dateFormat.format(prescription.weightDate!)})' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (reminder != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isReminderSoon
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Supprimer',
            ),
          ],
        ),
      ),
    );
  }
}
