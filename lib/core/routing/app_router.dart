import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/assistant_profile/domain/entities/assistant.dart';
import '../../features/assistant_profile/presentation/controllers/assistant_profile_controller.dart';
import '../../features/assistant_profile/presentation/pages/assistant_profile_page.dart';
import '../../features/children/domain/entities/child.dart';
import '../../features/children/presentation/pages/archive_pdfs_page.dart';
import '../../features/children/presentation/pages/child_detail_page.dart';
import '../../features/children/presentation/pages/pdf_preview_page.dart';
import '../../features/children/presentation/pages/child_edit_page.dart';
import '../../features/children/presentation/pages/schedule_change_page.dart';
import '../../features/children/presentation/pages/children_archives_page.dart';
import '../../features/children/presentation/pages/children_list_page.dart';
import '../../features/about/presentation/pages/about_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/diseases/domain/entities/disease_entry.dart';
import '../../features/diseases/presentation/pages/disease_form_page.dart';
import '../../features/diseases/presentation/pages/diseases_page.dart';
import '../../features/medications/domain/entities/medication_entry.dart';
import '../../features/medications/presentation/pages/medication_form_page.dart';
import '../../features/medications/presentation/pages/medications_page.dart';
import '../../features/vaccinations/presentation/pages/vaccination_rules_page.dart';
import '../../features/vaccinations/presentation/pages/vaccinations_page.dart';
import 'route_paths.dart';

bool _isProfileComplete(Assistant? a) {
  if (a == null) return false;
  return a.firstName.trim().isNotEmpty &&
      a.lastName.trim().isNotEmpty &&
      a.address.trim().isNotEmpty &&
      a.approvalNumber.trim().isNotEmpty;
}

final appRouterProvider = Provider<GoRouter>(
  (ref) {
    return GoRouter(
      initialLocation: RoutePaths.home,
      redirect: (context, state) async {
        if (kIsWeb) return null;
        if (state.matchedLocation == RoutePaths.assistantProfile) return null;
        try {
          final getProfile = ref.read(getAssistantProfileProvider);
          final assistant = await getProfile.call();
          if (!_isProfileComplete(assistant)) return RoutePaths.assistantProfile;
        } catch (_) {
          return RoutePaths.assistantProfile;
        }
        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: RoutePaths.home,
          pageBuilder: (context, state) {
            return const MaterialPage(
              child: HomePage(),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.about,
          pageBuilder: (context, state) {
            return const MaterialPage(
              child: AboutPage(),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.assistantProfile,
          pageBuilder: (context, state) {
            return const MaterialPage(
              child: AssistantProfilePage(),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.children,
          pageBuilder: (context, state) {
            return MaterialPage(
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Enfants accueillis'),
                ),
                body: const Padding(
                  padding: EdgeInsets.all(16),
                  child: ChildrenListPage(),
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.childrenNew,
          pageBuilder: (context, state) {
            return const MaterialPage(
              child: ChildEditPage(childId: null),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.childrenArchives,
          pageBuilder: (context, state) {
            return const MaterialPage(
              child: ChildrenArchivesPage(),
            );
          },
        ),
        GoRoute(
          path: '/children/:id',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            final fromArchives = state.extra == true;
            return MaterialPage(
              child: ChildDetailPage(childId: id, fromArchives: fromArchives),
            );
          },
        ),
        GoRoute(
          path: '/children/:id/edit',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return MaterialPage(
              child: ChildEditPage(childId: id),
            );
          },
        ),
        GoRoute(
          path: '/children/:id/schedule-change',
          pageBuilder: (context, state) {
            final child = state.extra as Child;
            return MaterialPage(
              child: ScheduleChangePage(child: child),
            );
          },
        ),
        GoRoute(
          path: '/children/:id/archive-pdfs',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return MaterialPage(
              child: ArchivePdfsPage(childId: id),
            );
          },
        ),
        GoRoute(
          path: '/children/:id/vaccinations',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return MaterialPage(
              child: VaccinationsPage(childId: id),
            );
          },
        ),
        GoRoute(
          path: '/children/:id/medications',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return MaterialPage(
              child: MedicationsPage(childId: id),
            );
          },
          routes: [
            GoRoute(
              path: 'new',
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
                return MaterialPage(
                  child: MedicationFormPage(childId: id, entry: null),
                );
              },
            ),
            GoRoute(
              path: 'edit/:medId',
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
                final entry = state.extra as MedicationEntry?;
                return MaterialPage(
                  child: MedicationFormPage(childId: id, entry: entry),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/children/:id/diseases',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return MaterialPage(
              child: DiseasesPage(childId: id),
            );
          },
          routes: [
            GoRoute(
              path: 'new',
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
                return MaterialPage(
                  child: DiseaseFormPage(childId: id, entry: null),
                );
              },
            ),
            GoRoute(
              path: 'edit/:diseaseId',
              pageBuilder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
                final entry = state.extra as DiseaseEntry?;
                return MaterialPage(
                  child: DiseaseFormPage(childId: id, entry: entry),
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/children/:id/quick-messages',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return MaterialPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('Messages WhatsApp')),
                body: Center(child: Text('Module Messages (enfant $id) – à venir')),
              ),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.pdfPreview,
          pageBuilder: (context, state) {
            final args = state.extra as PdfPreviewArgs;
            return MaterialPage(
              child: PdfPreviewPage(args: args),
            );
          },
        ),
        GoRoute(
          path: RoutePaths.vaccinationRules,
          pageBuilder: (context, state) {
            return const MaterialPage(
              child: VaccinationRulesPage(),
            );
          },
        ),
      ],
      errorBuilder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Erreur'),
          ),
          body: Center(
            child: Text(
              state.error?.toString() ?? 'Page introuvable',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  },
);

