import '../../domain/entities/disease_entry.dart';

class DiseaseEntryModel {
  const DiseaseEntryModel({
    required this.id,
    required this.childId,
    required this.name,
    this.dateMonth,
    this.dateYear,
    this.dateDay,
  });

  final int id;
  final int childId;
  final String name;
  final int? dateMonth;
  final int? dateYear;
  final int? dateDay;

  factory DiseaseEntryModel.fromMap(Map<String, Object?> map) {
    return DiseaseEntryModel(
      id: (map['id'] as int?) ?? 0,
      childId: (map['child_id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
      dateMonth: map['date_month'] as int?,
      dateYear: map['date_year'] as int?,
      dateDay: map['date_day'] as int?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id == 0 ? null : id,
      'child_id': childId,
      'name': name,
      'date_month': dateMonth,
      'date_year': dateYear,
      'date_day': dateDay,
    };
  }

  DiseaseEntry toEntity() {
    return DiseaseEntry(
      id: id,
      childId: childId,
      name: name,
      dateMonth: dateMonth,
      dateYear: dateYear,
      dateDay: dateDay,
    );
  }

  static DiseaseEntryModel fromEntity(DiseaseEntry e) {
    return DiseaseEntryModel(
      id: e.id,
      childId: e.childId,
      name: e.name,
      dateMonth: e.dateMonth,
      dateYear: e.dateYear,
      dateDay: e.dateDay,
    );
  }
}
