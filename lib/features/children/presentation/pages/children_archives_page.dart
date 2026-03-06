import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/photo/photo_helper.dart';
import '../../../../core/routing/route_paths.dart';
import '../../domain/entities/child.dart';
import '../controllers/children_controllers.dart';

class ChildrenArchivesPage extends ConsumerStatefulWidget {
  const ChildrenArchivesPage({super.key});

  @override
  ConsumerState<ChildrenArchivesPage> createState() => _ChildrenArchivesPageState();
}

class _ChildrenArchivesPageState extends ConsumerState<ChildrenArchivesPage> {
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _confirmAndDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Suppression définitive'),
        content: Text(
          'Cette action est irréversible. Les $count enfant${count > 1 ? 's' : ''} sélectionné${count > 1 ? 's' : ''} '
          'et toutes leurs données (contrat, vaccins, médicaments, maladies) seront définitivement supprimés.\n\n'
          'Voulez-vous vraiment continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final deleteChild = ref.read(deleteArchivedChildProvider);
    try {
      for (final id in _selectedIds) {
        await deleteChild.call(id);
      }
      if (!mounted) return;
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
      ref.invalidate(archivedChildrenControllerProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(archivedChildrenControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectionMode && _selectedIds.isNotEmpty
            ? '${_selectedIds.length} sélectionné(s)'
            : 'Archives'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selectionMode) {
              setState(() {
                _selectionMode = false;
                _selectedIds.clear();
              });
            } else {
              context.go(RoutePaths.home);
            }
          },
        ),
        actions: [
          if (asyncState.hasValue &&
              asyncState.value!.isStorageAvailable &&
              asyncState.value!.children.isNotEmpty) ...[
            TextButton(
              onPressed: _toggleSelectionMode,
              child: Text(_selectionMode ? 'Annuler' : 'Sélectionner'),
            ),
            if (_selectionMode && _selectedIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Supprimer la sélection',
                onPressed: _confirmAndDelete,
              ),
          ],
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erreur : $e')),
        data: (state) {
          if (!state.isStorageAvailable) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Le stockage local n’est pas disponible dans le navigateur.\n'
                'Les archives sont visibles sur macOS, iOS ou Android.',
              ),
            );
          }
          if (state.children.isEmpty) {
            return const Center(
              child: Text('Aucun enfant archivé.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.children.length,
            itemBuilder: (context, index) {
              final child = state.children[index];
              return _ArchiveChildCard(
                child: child,
                selectionMode: _selectionMode,
                selected: _selectedIds.contains(child.id),
                onToggleSelection: () => _toggleSelection(child.id),
                onTap: () {
                  if (_selectionMode) {
                    _toggleSelection(child.id);
                  } else {
                    context.push('/children/${child.id}', extra: true);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ArchiveChildCard extends StatelessWidget {
  const _ArchiveChildCard({
    required this.child,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelection,
    required this.onTap,
  });

  final Child child;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: selectionMode
            ? Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelection(),
              )
            : buildChildPhotoAvatar(
                context: context,
                photoPath: child.photoPath,
                initial: child.firstName.isNotEmpty
                    ? child.firstName.characters.first
                    : '?',
                radius: 22,
              ),
        title: Text('${child.firstName} ${child.lastName}'),
        subtitle: Text(
          child.contractEndDate != null
              ? 'Fin de contrat : ${child.contractEndDate!.day.toString().padLeft(2, '0')}/'
                  '${child.contractEndDate!.month.toString().padLeft(2, '0')}/'
                  '${child.contractEndDate!.year}'
              : 'Archivé',
        ),
        trailing: selectionMode ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
