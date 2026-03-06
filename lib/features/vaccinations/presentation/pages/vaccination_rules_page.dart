import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vaccination_rule.dart';
import '../controllers/vaccination_controllers.dart';

final vaccinationRulesListProvider = FutureProvider<List<VaccinationRule>>((ref) async {
  if (kIsWeb) return [];
  return ref.read(getVaccinationRulesProvider).call();
});

class VaccinationRulesPage extends ConsumerWidget {
  const VaccinationRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(vaccinationRulesListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Liste des vaccins obligatoires'),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(
              child: Text('Aucune règle. La liste par défaut sera créée au premier lancement.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final r = rules[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(r.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Délai : ${r.delayMonths} mois après la naissance'),
                      if (r.notes != null && r.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            r.notes!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: r.notes != null && r.notes!.isNotEmpty,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditRuleDialog(context, ref, r),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRuleDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un vaccin'),
      ),
    );
  }

  Future<void> _showAddRuleDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final monthsCtrl = TextEditingController(text: '2');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau vaccin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom du vaccin'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: monthsCtrl,
              decoration: const InputDecoration(
                labelText: 'Délai (mois après la naissance)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final name = nameCtrl.text.trim();
      final months = int.tryParse(monthsCtrl.text.trim()) ?? 0;
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Indiquez le nom du vaccin.')),
        );
        return;
      }
      final rules = await ref.read(getVaccinationRulesProvider).call();
      await ref.read(saveVaccinationRuleProvider).insert(
            VaccinationRule(
              id: 0,
              name: name,
              delayMonths: months,
              sortOrder: rules.length,
              notes: null,
            ),
          );
      if (context.mounted) {
        ref.invalidate(vaccinationRulesListProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vaccin ajouté.')));
      }
    }
  }

  Future<void> _showEditRuleDialog(BuildContext context, WidgetRef ref, VaccinationRule r) async {
    final nameCtrl = TextEditingController(text: r.name);
    final monthsCtrl = TextEditingController(text: '${r.delayMonths}');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le vaccin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom du vaccin'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: monthsCtrl,
              decoration: const InputDecoration(
                labelText: 'Délai (mois après la naissance)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      final name = nameCtrl.text.trim();
      final months = int.tryParse(monthsCtrl.text.trim()) ?? r.delayMonths;
      await ref.read(saveVaccinationRuleProvider).update(
            r.copyWith(name: name, delayMonths: months),
          );
      if (context.mounted) {
        ref.invalidate(vaccinationRulesListProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modification enregistrée.')));
      }
    }
  }
}
