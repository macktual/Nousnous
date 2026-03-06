/// Règle de vaccination : nom du vaccin, délai en mois, et éventuellement notes (variantes, noms commerciaux).
class VaccinationRule {
  const VaccinationRule({
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
  /// Notes officielles (ex. * ** variantes selon année de naissance, type de produit).
  final String? notes;

  VaccinationRule copyWith({
    int? id,
    String? name,
    int? delayMonths,
    int? sortOrder,
    String? notes,
  }) {
    return VaccinationRule(
      id: id ?? this.id,
      name: name ?? this.name,
      delayMonths: delayMonths ?? this.delayMonths,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
    );
  }
}
