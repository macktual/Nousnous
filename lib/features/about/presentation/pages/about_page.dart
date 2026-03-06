import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Page À propos / Mentions légales – propriété intellectuelle et restrictions d’usage.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'nousnous',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Application de gestion pour assistante maternelle.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Propriété intellectuelle',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2025 Franck Tual – Tous droits réservés.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Ce logiciel et l’ensemble du code source, des interfaces et des fonctionnalités sont la propriété exclusive de Franck Tual. Aucune partie de ce projet ne peut être considérée comme libre de droits.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'Restrictions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sans autorisation écrite préalable, il est interdit de :\n'
            '• Copier tout ou partie du code ou des ressources\n'
            '• Modifier le logiciel pour en créer une version dérivée\n'
            '• Partager, distribuer ou publier le code ou les binaires\n'
            '• Revendre ou réutiliser des éléments du projet dans un autre logiciel',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Text(
            'L’utilisation de l’application est réservée à l’usage personnel ou professionnel pour lequel elle a été conçue. Toute autre utilisation doit faire l’objet d’un accord explicite.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
