/// Entrée de maladie pour un enfant (nom + date optionnelle, jour optionnel).
class DiseaseEntry {
  const DiseaseEntry({
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
  /// 1–12 si renseigné
  final int? dateMonth;
  /// ex. 2024
  final int? dateYear;
  /// 1–31 si renseigné (optionnel : sinon affichage mois/année uniquement)
  final int? dateDay;
}
