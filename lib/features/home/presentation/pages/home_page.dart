import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../children/presentation/controllers/children_controllers.dart';
import '../../../children/presentation/pages/children_list_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChildren = ref.watch(activeChildrenControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes contrats'),
        actions: [
          IconButton(
            tooltip: 'À propos / Mentions légales',
            onPressed: () => context.push(RoutePaths.about),
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            tooltip: 'Archives',
            onPressed: () => context.push(RoutePaths.childrenArchives),
            icon: const Icon(Icons.archive),
          ),
          IconButton(
            tooltip: 'Profil assistant maternel',
            onPressed: () => context.push(RoutePaths.assistantProfile),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enfants accueillis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ChildrenListPage(
                key: ValueKey(activeChildren.hashCode),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.childrenNew),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un enfant'),
      ),
    );
  }
}

