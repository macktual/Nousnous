import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/backup/file_backup_service.dart';
import '../../../../core/backup/icloud_backup_service.dart';
import '../../../../core/db/app_database_provider.dart';
import '../../../assistant_profile/presentation/controllers/assistant_profile_controller.dart';
import '../../../children/presentation/controllers/children_controllers.dart';
import '../../../medications/presentation/controllers/medication_controllers.dart';

/// Lien PayPal.Me pour les dons (hors iOS : App Store exige l’IAP pour ce type de soutien — guideline 3.1.1).
const String _paypalDonateUrl = 'https://paypal.me/cestoim';

bool get _showPayPalDonation =>
    defaultTargetPlatform != TargetPlatform.iOS;

/// Page À propos / Mentions légales – propriété intellectuelle et restrictions d’usage.
class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  bool _icloudBusy = false;
  String? _icloudStatus;
  int _icloudMetaRefresh = 0;
  bool _fileBusy = false;
  String? _fileStatus;
  bool _fileStatusIsError = false;

  Future<void> _openPayPalDonate() async {
    final uri = Uri.parse(_paypalDonateUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _invalidateAfterRestore() {
    ref.invalidate(assistantProfileControllerProvider);
    ref.invalidate(activeChildrenControllerProvider);
    ref.invalidate(archivedChildrenControllerProvider);
    ref.invalidate(medicationNamesProvider);
  }

  Future<void> _uploadIcloud() async {
    setState(() {
      _icloudBusy = true;
      _icloudStatus = null;
    });
    try {
      final db = ref.read(appDatabaseProvider);
      await IcloudBackupService.uploadBackup(db);
      if (mounted) {
        setState(() {
          _icloudStatus = 'Sauvegarde envoyée sur iCloud. La synchronisation peut prendre quelques minutes.';
          _icloudMetaRefresh++;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _icloudStatus = e.toString());
      }
    } finally {
      if (mounted) setState(() => _icloudBusy = false);
    }
  }

  Future<void> _confirmRestore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer depuis iCloud ?'),
        content: const Text(
          'Les données actuelles de cet appareil (enfants, profil, photos locales, etc.) seront remplacées par la sauvegarde iCloud. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _icloudBusy = true;
      _icloudStatus = null;
    });
    try {
      final db = ref.read(appDatabaseProvider);
      await IcloudBackupService.restoreBackup(db);
      await FileBackupService.rescheduleDolipraneReminders(db);
      _invalidateAfterRestore();
      if (mounted) {
        setState(() => _icloudStatus = 'Restauration terminée. Fermez complètement l’app puis rouvrez-la si un écran affiche encore d’anciennes données.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _icloudStatus = e.toString());
      }
    } finally {
      if (mounted) setState(() => _icloudBusy = false);
    }
  }

  Future<void> _exportToFile() async {
    setState(() {
      _fileBusy = true;
      _fileStatus = null;
    });
    try {
      final db = ref.read(appDatabaseProvider);
      final saved = await FileBackupService.exportBackup(db);
      if (mounted && saved) {
        setState(() {
          _fileStatus = 'Sauvegarde enregistrée. Gardez ce fichier en lieu sûr (Google Drive, e-mail, ordinateur…).';
          _fileStatusIsError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileStatus = 'Échec de la sauvegarde : ${_errorText(e)}';
          _fileStatusIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _fileBusy = false);
    }
  }

  Future<void> _confirmImportFromFile() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer une sauvegarde ?'),
        content: const Text(
          'Toutes les données actuelles de l’app (enfants, profil, photos, signatures…) seront remplacées par celles du fichier choisi. Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Choisir le fichier'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _fileBusy = true;
      _fileStatus = null;
    });
    try {
      final db = ref.read(appDatabaseProvider);
      final restored = await FileBackupService.importBackup(db);
      if (restored) {
        _invalidateAfterRestore();
        if (mounted) {
          setState(() {
            _fileStatus = 'Restauration terminée. Fermez complètement l’app puis rouvrez-la si un écran affiche encore d’anciennes données.';
            _fileStatusIsError = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileStatus = 'Échec de la restauration : ${_errorText(e)}';
          _fileStatusIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _fileBusy = false);
    }
  }

  String _errorText(Object e) => e is StateError ? e.message : e.toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showIcloud = IcloudBackupService.isSupported;

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
            'easynounou',
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
          const SizedBox(height: 10),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Version…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Version : non disponible',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              final info = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Version installée : ${info.version} (build ${info.buildNumber})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
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
          if (showIcloud) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Sauvegarde iCloud',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enregistrez une copie de vos données (base + photos) dans le dossier iCloud de l’app, sur le même compte Apple que vos autres appareils. '
              'Ce n’est pas une synchronisation instantanée : iOS peut mettre un peu de temps à propager le fichier.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              key: ValueKey(_icloudMetaRefresh),
              future: _icloudMeta(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }
                final available = snap.data?['available'] == true;
                final has = snap.data?['has'] == true;
                final modified = snap.data?['modified'] as DateTime?;
                if (!available) {
                  return Text(
                    'iCloud n’est pas disponible (connexion ou iCloud Drive désactivé).',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  );
                }
                if (has && modified != null) {
                  final fmt = DateFormat.yMMMd('fr_FR').add_Hm();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Dernière sauvegarde sur iCloud : ${fmt.format(modified)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Aucune sauvegarde sur iCloud pour l’instant.',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _icloudBusy ? null : _uploadIcloud,
                    icon: _icloudBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined, size: 20),
                    label: const Text('Enregistrer sur iCloud'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _icloudBusy ? null : _confirmRestore,
                    icon: const Icon(Icons.cloud_download_outlined, size: 20),
                    label: const Text('Restaurer'),
                  ),
                ),
              ],
            ),
            if (_icloudStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                _icloudStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _icloudStatus!.contains('terminée') || _icloudStatus!.contains('envoyée')
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ],
          if (FileBackupService.isSupported) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Sauvegarde dans un fichier',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez un fichier contenant toutes vos données (enfants, profil, photos, signatures) et gardez-le dans Google Drive, '
              'vos Téléchargements ou envoyez-le-vous par e-mail. Indispensable avant de changer de téléphone ou de réinstaller l’app.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _fileBusy ? null : _exportToFile,
                    icon: _fileBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_alt, size: 20),
                    label: const Text('Sauvegarder'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _fileBusy ? null : _confirmImportFromFile,
                    icon: const Icon(Icons.restore, size: 20),
                    label: const Text('Restaurer'),
                  ),
                ),
              ],
            ),
            if (_fileStatus != null) ...[
              const SizedBox(height: 8),
              Text(
                _fileStatus!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _fileStatusIsError ? theme.colorScheme.error : theme.colorScheme.primary,
                ),
              ),
            ],
          ],
          if (_showPayPalDonation) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Soutien',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Si cette application vous est utile, vous pouvez soutenir son développement par un don via PayPal.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openPayPalDonate,
              icon: const Icon(Icons.volunteer_activism, size: 20),
              label: const Text('Faire un don via PayPal'),
            ),
          ],
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _icloudMeta() async {
    if (!IcloudBackupService.isSupported) {
      return {'available': false, 'has': false};
    }
    final available = await IcloudBackupService.isICloudAvailable();
    if (!available) {
      return {'available': false, 'has': false};
    }
    final has = await IcloudBackupService.hasRemoteBackup();
    final modified = await IcloudBackupService.remoteBackupModified();
    return {'available': true, 'has': has, 'modified': modified};
  }
}
