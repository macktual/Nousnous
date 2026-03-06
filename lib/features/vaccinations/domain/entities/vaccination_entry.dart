import 'vaccination_rule.dart';

/// Entrée de vaccination pour un enfant : règle + date théorique + statut réel + justificatif.
class VaccinationEntry {
  const VaccinationEntry({
    required this.rule,
    required this.theoreticalDate,
    required this.actualDate,
    required this.isDone,
    this.justificationSource,
    this.justificationDate,
    this.justificationPhotoPath,
  });

  final VaccinationRule rule;
  final DateTime theoreticalDate;
  final DateTime? actualDate;
  final bool isDone;
  /// Source du justificatif (ex. WhatsApp, email, papier).
  final String? justificationSource;
  /// Date du justificatif.
  final DateTime? justificationDate;
  /// Chemin vers la photo du reçu (reçu du parent).
  final String? justificationPhotoPath;
}
