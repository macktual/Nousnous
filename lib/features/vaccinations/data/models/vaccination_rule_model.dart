import '../../domain/entities/vaccination_rule.dart';

class VaccinationRuleModel {
  const VaccinationRuleModel({
    required this.id,
    required this.name,
    required this.delayMonths,
    required this.sortOrder,
    this.notes,
  });

  final int id;
  final String name;
  final int delayMonths;
  final int sortOrder;
  final String? notes;

  factory VaccinationRuleModel.fromMap(Map<String, Object?> map) {
    return VaccinationRuleModel(
      id: (map['id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
      delayMonths: (map['delay_months'] as int?) ?? 0,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'delay_months': delayMonths,
      'sort_order': sortOrder,
      'notes': notes,
    };
  }

  VaccinationRule toEntity() {
    return VaccinationRule(
      id: id,
      name: name,
      delayMonths: delayMonths,
      sortOrder: sortOrder,
      notes: notes,
    );
  }

  static VaccinationRuleModel fromEntity(VaccinationRule r) {
    return VaccinationRuleModel(
      id: r.id,
      name: r.name,
      delayMonths: r.delayMonths,
      sortOrder: r.sortOrder,
      notes: r.notes,
    );
  }
}
