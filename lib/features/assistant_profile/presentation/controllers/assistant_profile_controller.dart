import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../data/datasources/assistant_local_datasource.dart';
import '../../data/repositories/assistant_repository_impl.dart';
import '../../domain/entities/assistant.dart';
import '../../domain/usecases/get_assistant_profile.dart';
import '../../domain/usecases/save_assistant_profile.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final assistantLocalDatasourceProvider = Provider<AssistantLocalDatasource>((ref) {
  return AssistantLocalDatasource(ref.watch(appDatabaseProvider));
});

final assistantRepositoryProvider = Provider<AssistantRepositoryImpl>((ref) {
  return AssistantRepositoryImpl(ref.watch(assistantLocalDatasourceProvider));
});

final getAssistantProfileProvider = Provider<GetAssistantProfile>((ref) {
  return GetAssistantProfile(ref.watch(assistantRepositoryProvider));
});

final saveAssistantProfileProvider = Provider<SaveAssistantProfile>((ref) {
  return SaveAssistantProfile(ref.watch(assistantRepositoryProvider));
});

final assistantProfileControllerProvider =
    AsyncNotifierProvider<AssistantProfileController, AssistantProfileState>(
  AssistantProfileController.new,
);

class AssistantProfileState {
  const AssistantProfileState({
    required this.isStorageAvailable,
    required this.assistant,
  });

  final bool isStorageAvailable;
  final Assistant? assistant;
}

class AssistantProfileController extends AsyncNotifier<AssistantProfileState> {
  @override
  Future<AssistantProfileState> build() async {
    final storageAvailable = !kIsWeb;
    if (!storageAvailable) {
      return const AssistantProfileState(
        isStorageAvailable: false,
        assistant: null,
      );
    }

    final assistant = await ref.watch(getAssistantProfileProvider).call();
    return AssistantProfileState(
      isStorageAvailable: true,
      assistant: assistant,
    );
  }

  String _toTitleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed
        .split(RegExp(r'\\s+'))
        .where((p) => p.isNotEmpty)
        .map((word) {
          final lower = word.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .join(' ');
  }

  Future<void> save({
    required String firstName,
    required String lastName,
    required String address,
    required String approvalNumber,
    required DateTime approvalDate,
    String? civility,
    String? postalCode,
    String? city,
    String? phone,
    String? email,
    int? agreementMaxChildren,
    String? accessCode,
    String? floor,
    String? signaturePath,
  }) async {
    final current = state.valueOrNull;
    if (current == null || !current.isStorageAvailable) return;

    state = const AsyncLoading();

    final assistant = Assistant(
      id: 1,
      firstName: _toTitleCase(firstName),
      lastName: _toTitleCase(lastName),
      address: address.trim(),
      approvalNumber: approvalNumber.trim(),
      approvalDate: approvalDate,
      civility: civility?.trim().isEmpty == true ? null : civility?.trim(),
      postalCode: postalCode?.trim().isEmpty == true ? null : postalCode?.trim(),
      city: city?.trim().isEmpty == true ? null : city?.trim(),
      phone: phone?.trim().isEmpty == true ? null : phone?.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      agreementMaxChildren: agreementMaxChildren != null && agreementMaxChildren >= 1 && agreementMaxChildren <= 4 ? agreementMaxChildren : null,
      accessCode: accessCode?.trim().isEmpty == true ? null : accessCode?.trim(),
      floor: floor?.trim().isEmpty == true ? null : floor?.trim(),
      signaturePath: signaturePath ?? current.assistant?.signaturePath,
    );

    await ref.watch(saveAssistantProfileProvider).call(assistant);

    state = AsyncData(
      AssistantProfileState(
        isStorageAvailable: true,
        assistant: assistant,
      ),
    );
  }
}

