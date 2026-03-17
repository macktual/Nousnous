/// Ordonnance Doliprane : dates, poids de l'enfant, rappel avant fin, photo.
/// Durée fixe : 6 mois (non modifiable). On n'affiche que la date de fin.
class DolipranePrescription {
  /// Durée de validité de l'ordonnance en mois (non modifiable).
  static const int validityMonths = 6;

  const DolipranePrescription({
    required this.id,
    required this.childId,
    required this.startDate,
    required this.endDate,
    this.prescriptionDate,
    this.childWeightKg,
    this.weightDate,
    this.reminderWeeksBeforeEnd,
    this.photoPath,
  });

  final int id;
  final int childId;
  /// Date de début de l'ordonnance.
  final DateTime startDate;
  /// Date de fin de l'ordonnance.
  final DateTime endDate;
  /// Date d'établissement / enregistrement de l'ordonnance.
  final DateTime? prescriptionDate;
  /// Poids de l'enfant (kg) au moment de l'ordonnance.
  final double? childWeightKg;
  /// Date à laquelle le poids a été pris.
  final DateTime? weightDate;
  /// Nombre de semaines avant la fin pour déclencher un rappel (X défini par l'utilisateur).
  final int? reminderWeeksBeforeEnd;
  /// Chemin vers la photo de l'ordonnance.
  final String? photoPath;

  /// Date à laquelle le rappel doit être affiché (fin - X semaines).
  DateTime? get reminderDate {
    if (reminderWeeksBeforeEnd == null || reminderWeeksBeforeEnd! <= 0) return null;
    return endDate.subtract(Duration(days: reminderWeeksBeforeEnd! * 7));
  }

  /// Indique si le rappel est déjà passé (on est après la date de rappel).
  bool get isReminderPassed {
    final rd = reminderDate;
    if (rd == null) return false;
    return DateTime.now().isAfter(rd);
  }
}
