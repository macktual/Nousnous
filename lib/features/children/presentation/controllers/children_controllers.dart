import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/db/app_database.dart';
import '../../data/datasources/child_local_datasource.dart';
import '../../data/repositories/child_repository_impl.dart';
import '../../domain/entities/child.dart';
import '../../domain/repositories/child_repository.dart';
import '../../domain/usecases/add_schedule_change.dart';
import '../../domain/usecases/archive_child.dart';
import '../../domain/usecases/create_child.dart';
import '../../domain/usecases/delete_archived_child.dart';
import '../../domain/usecases/get_active_children.dart';
import '../../domain/usecases/get_archived_children.dart';
import '../../domain/usecases/get_child_detail.dart';
import '../../domain/usecases/update_child.dart';

final childAppDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final childLocalDatasourceProvider = Provider<ChildLocalDatasource>((ref) {
  return ChildLocalDatasource(ref.watch(childAppDatabaseProvider));
});

final childRepositoryProvider = Provider<ChildRepository>((ref) {
  return ChildRepositoryImpl(ref.watch(childLocalDatasourceProvider));
});

final getActiveChildrenProvider = Provider<GetActiveChildren>((ref) {
  return GetActiveChildren(ref.watch(childRepositoryProvider));
});

final getArchivedChildrenProvider = Provider<GetArchivedChildren>((ref) {
  return GetArchivedChildren(ref.watch(childRepositoryProvider));
});

final getChildDetailProvider = Provider<GetChildDetail>((ref) {
  return GetChildDetail(ref.watch(childRepositoryProvider));
});

final createChildProvider = Provider<CreateChild>((ref) {
  return CreateChild(ref.watch(childRepositoryProvider));
});

final updateChildProvider = Provider<UpdateChild>((ref) {
  return UpdateChild(ref.watch(childRepositoryProvider));
});

final addScheduleChangeProvider = Provider<AddScheduleChange>((ref) {
  return AddScheduleChange(ref.watch(childRepositoryProvider));
});

final archiveChildProvider = Provider<ArchiveChild>((ref) {
  return ArchiveChild(ref.watch(childRepositoryProvider));
});

final deleteArchivedChildProvider = Provider<DeleteArchivedChild>((ref) {
  return DeleteArchivedChild(ref.watch(childRepositoryProvider));
});

final childDetailProvider = FutureProvider.family<Child?, int>((ref, childId) async {
  if (kIsWeb) return null;
  return ref.watch(getChildDetailProvider).call(childId);
});

class ChildrenListState {
  const ChildrenListState({
    required this.isStorageAvailable,
    required this.children,
  });

  final bool isStorageAvailable;
  final List<Child> children;
}

final activeChildrenControllerProvider =
    AsyncNotifierProvider<ActiveChildrenController, ChildrenListState>(
  ActiveChildrenController.new,
);

final archivedChildrenControllerProvider =
    AsyncNotifierProvider<ArchivedChildrenController, ChildrenListState>(
  ArchivedChildrenController.new,
);

class ActiveChildrenController extends AsyncNotifier<ChildrenListState> {
  @override
  Future<ChildrenListState> build() async {
    if (kIsWeb) {
      return const ChildrenListState(
        isStorageAvailable: false,
        children: <Child>[],
      );
    }
    final children = await ref.watch(getActiveChildrenProvider).call();
    return ChildrenListState(
      isStorageAvailable: true,
      children: children,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

class ArchivedChildrenController extends AsyncNotifier<ChildrenListState> {
  @override
  Future<ChildrenListState> build() async {
    if (kIsWeb) {
      return const ChildrenListState(
        isStorageAvailable: false,
        children: <Child>[],
      );
    }
    final children = await ref.watch(getArchivedChildrenProvider).call();
    return ChildrenListState(
      isStorageAvailable: true,
      children: children,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await build());
  }
}

