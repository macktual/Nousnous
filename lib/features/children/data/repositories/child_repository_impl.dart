import 'package:intl/intl.dart';

import '../../domain/entities/child.dart';
import '../../domain/entities/parent.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/weekly_pattern.dart';
import '../../domain/repositories/child_repository.dart';
import '../datasources/child_local_datasource.dart';
import '../models/child_model.dart';

class ChildRepositoryImpl implements ChildRepository {
  ChildRepositoryImpl(this._local);

  final ChildLocalDatasource _local;

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  Future<List<Child>> getActiveChildren() async {
    final models = await _local.getChildren(archived: false);
    return _withAggregates(models);
  }

  @override
  Future<List<Child>> getArchivedChildren() async {
    final models = await _local.getChildren(archived: true);
    return _withAggregates(models);
  }

  @override
  Future<Child?> getChildById(int id) async {
    final model = await _local.getChild(id);
    if (model == null) return null;
    final parents = await _local.getParents(model.id);
    final patterns = await _local.getPatterns(model.id);
    final weeklyPatterns = <WeeklyPattern>[];
    for (final p in patterns) {
      final entriesModels = await _local.getEntriesForPattern(p.id);
      final entries = entriesModels.map((e) => e.toEntity()).toList();
      weeklyPatterns.add(p.toEntity(entries));
    }
    final parentEntities = parents.map((p) => p.toEntity()).toList();
    return model.toEntity(
      parents: parentEntities,
      patterns: weeklyPatterns,
    );
  }

  @override
  Future<int> createChild(Child child) async {
    final model = ChildModel.fromEntity(child);
    final parents = child.parents
        .map(
          (p) => ParentModel.fromEntity(
            ParentInfo(
              id: 0,
              childId: 0,
              role: p.role,
              firstName: p.firstName,
              lastName: p.lastName,
              address: p.address,
              phone: p.phone,
              email: p.email,
              postalCode: p.postalCode,
              city: p.city,
            ),
          ),
        )
        .toList();

    final patterns = child.weeklyPatterns
        .map(
          (w) => WeeklyPatternModel.fromEntity(
            WeeklyPattern(
              id: 0,
              childId: 0,
              name: w.name,
              isActive: w.isActive,
              entries: w.entries,
            ),
          ),
        )
        .toList();

    final entriesPerPatternInOrder = <List<ScheduleEntryModel>>[];
    for (final w in child.weeklyPatterns) {
      final entriesModels = w.entries
          .map(
            (e) => ScheduleEntryModel.fromEntity(
              ScheduleEntry(
                id: 0,
                patternId: 0,
                weekday: e.weekday,
                arrivalTime: e.arrivalTime,
                departureTime: e.departureTime,
              ),
            ),
          )
          .toList();
      entriesPerPatternInOrder.add(entriesModels);
    }

    return _local.insertChild(
      model,
      parents,
      patterns,
      entriesPerPatternInOrder,
    );
  }

  @override
  Future<void> updateChild(Child child) async {
    final existing = await _local.getChild(child.id);
    if (existing != null && existing.isArchived) {
      throw StateError('Impossible de modifier un enfant archivé.');
    }
    final model = ChildModel.fromEntity(child);

    final parents = child.parents
        .map(
          (p) => ParentModel.fromEntity(
            ParentInfo(
              id: p.id,
              childId: child.id,
              role: p.role,
              firstName: p.firstName,
              lastName: p.lastName,
              address: p.address,
              phone: p.phone,
              email: p.email,
              postalCode: p.postalCode,
              city: p.city,
            ),
          ),
        )
        .toList();

    final patterns = child.weeklyPatterns
        .map(
          (w) => WeeklyPatternModel.fromEntity(
            WeeklyPattern(
              id: w.id,
              childId: child.id,
              name: w.name,
              isActive: w.isActive,
              entries: w.entries,
            ),
          ),
        )
        .toList();

    final patternEntries = <int, List<ScheduleEntryModel>>{};
    for (var i = 0; i < child.weeklyPatterns.length; i++) {
      final key = patterns[i].id;
      final entriesModels = child.weeklyPatterns[i].entries
          .map(
            (e) => ScheduleEntryModel.fromEntity(
              ScheduleEntry(
                id: e.id,
                patternId: key,
                weekday: e.weekday,
                arrivalTime: e.arrivalTime,
                departureTime: e.departureTime,
              ),
            ),
          )
          .toList();
      patternEntries[key] = entriesModels;
    }

    return _local.updateChild(
      model,
      parents,
      patterns,
      patternEntries,
    );
  }

  @override
  Future<void> addScheduleChange(int childId, DateTime validFromDate, List<WeeklyPattern> newPatterns) async {
    final existing = await _local.getChild(childId);
    if (existing != null && existing.isArchived) {
      throw StateError('Impossible de modifier les horaires d\'un enfant archivé.');
    }
    final patterns = newPatterns
        .map(
          (w) => WeeklyPatternModel.fromEntity(
            WeeklyPattern(
              id: 0,
              childId: childId,
              name: w.name,
              isActive: w.isActive,
              entries: w.entries,
              validFrom: validFromDate,
              validUntil: null,
            ),
          ),
        )
        .toList();
    final entriesPerPatternInOrder = newPatterns
        .map(
          (w) => w.entries
              .map(
                (e) => ScheduleEntryModel.fromEntity(
                  ScheduleEntry(
                    id: 0,
                    patternId: 0,
                    weekday: e.weekday,
                    arrivalTime: e.arrivalTime,
                    departureTime: e.departureTime,
                  ),
                ),
              )
              .toList(),
        )
        .toList();
    return _local.addScheduleChange(childId, validFromDate, patterns, entriesPerPatternInOrder);
  }

  @override
  Future<void> archiveChild(int id, {DateTime? contractEndDate, String? particularitesFinContrat, String? archiveSignaturePath}) {
    return _local.archiveChild(
      id,
      contractEndDate: contractEndDate == null ? null : _dateFormat.format(contractEndDate),
      particularitesFinContrat: particularitesFinContrat,
      archiveSignaturePath: archiveSignaturePath,
    );
  }

  @override
  Future<void> deleteArchivedChild(int id) async {
    final existing = await _local.getChild(id);
    if (existing == null) {
      throw StateError('Enfant introuvable.');
    }
    if (!existing.isArchived) {
      throw StateError('Seuls les enfants archivés peuvent être supprimés définitivement.');
    }
    await _local.deleteChild(id);
  }

  Future<List<Child>> _withAggregates(List<ChildModel> models) async {
    final children = <Child>[];
    for (final model in models) {
      final parents = await _local.getParents(model.id);
      final patterns = await _local.getPatterns(model.id);
      final weeklyPatterns = <WeeklyPattern>[];
      for (final p in patterns) {
        final entriesModels = await _local.getEntriesForPattern(p.id);
        final entries = entriesModels.map((e) => e.toEntity()).toList();
        weeklyPatterns.add(p.toEntity(entries));
      }
      final parentEntities = parents.map((p) => p.toEntity()).toList();
      children.add(
        model.toEntity(
          parents: parentEntities,
          patterns: weeklyPatterns,
        ),
      );
    }
    return children;
  }
}

