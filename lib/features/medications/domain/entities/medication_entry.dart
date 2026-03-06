/// Entrée de médicament pour un enfant (une prise).
class MedicationEntry {
  const MedicationEntry({
    required this.id,
    required this.childId,
    required this.dateTime,
    required this.medicationName,
    this.posology,
    this.reason,
    this.administeredBy,
    this.notes,
  });

  final int id;
  final int childId;
  final DateTime dateTime;
  final String medicationName;
  final String? posology;
  final String? reason;
  final String? administeredBy;
  final String? notes;
}
