import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/photo/photo_helper.dart';
import '../../domain/entities/child.dart';
import '../controllers/children_controllers.dart';

class ChildrenListPage extends ConsumerWidget {
  const ChildrenListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(activeChildrenControllerProvider);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Erreur : $e')),
      data: (state) {
        if (!state.isStorageAvailable) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Le stockage local (SQLite) n’est pas disponible dans le navigateur.\n\n'
              'Pour gérer la liste des enfants de manière persistante, lancez l’app sur macOS, iOS ou Android.',
            ),
          );
        }

        if (state.children.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aucun enfant pour le moment.\nAjoutez un enfant avec le bouton “+”.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: state.children.length,
          itemBuilder: (context, index) {
            final child = state.children[index];
            return _ChildCard(child: child);
          },
        );
      },
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});

  final Child child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/children/${child.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              buildChildPhotoAvatar(
                context: context,
                photoPath: child.photoPath,
                initial: child.firstName.isNotEmpty
                    ? child.firstName.characters.first
                    : '?',
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${child.firstName} ${child.lastName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contrat depuis le '
                      '${child.contractStartDate.day.toString().padLeft(2, '0')}/'
                      '${child.contractStartDate.month.toString().padLeft(2, '0')}/'
                      '${child.contractStartDate.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

