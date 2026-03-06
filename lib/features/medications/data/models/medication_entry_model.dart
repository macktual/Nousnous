import '../../domain/entities/medication_entry.dart';

class MedicationEntryModel {
  const MedicationEntryModel({
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
  final String dateTime;
  final String medicationName;
  final String? posology;
  final String? reason;
  final String? administeredBy;
  final String? notes;

  factory MedicationEntryModel.fromMap(Map<String, Object?> map) {
    return MedicationEntryModel(
      id: (map['id'] as int?) ?? 0,
      childId: (map['child_id'] as int?) ?? 0,
      dateTime: (map['date_time'] as String?) ?? '',
      medicationName: (map['medication_name'] as String?) ?? '',
      posology: map['posology'] as String?,
      reason: map['reason'] as String?,
      administeredBy: map['administered_by'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id == 0 ? null : id,
      'child_id': childId,
      'date_time': dateTime,
      'medication_name': medicationName,
      'posology': posology,
      'reason': reason,
      'administered_by': administeredBy,
      'notes': notes,
    };
  }

  MedicationEntry toEntity() {
    return MedicationEntry(
      id: id,
      childId: childId,
      dateTime: _parseDateTime(dateTime),
      medicationName: medicationName,
      posology: posology,
      reason: reason,
      administeredBy: administeredBy,
      notes: notes,
    );
  }

  static DateTime _parseDateTime(String s) {
    if (s.isEmpty) return DateTime.now();
    try {
      return DateTime.parse(s.replaceFirst(' ', 'T'));
    } catch (_) {
      return DateTime.now();
    }
  }

  static MedicationEntryModel fromEntity(MedicationEntry e) {
    return MedicationEntryModel(
      id: e.id,
      childId: e.childId,
      dateTime: _toIsoDateTime(e.dateTime),
      medicationName: e.medicationName,
      posology: e.posology,
      reason: e.reason,
      administeredBy: e.administeredBy,
      notes: e.notes,
    );
  }

  static String _toIsoDateTime(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
  }
}
