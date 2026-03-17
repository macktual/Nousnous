import '../../domain/entities/doliprane_prescription.dart';

class DolipranePrescriptionModel {
  const DolipranePrescriptionModel({
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
  final String startDate;
  final String endDate;
  final String? prescriptionDate;
  final double? childWeightKg;
  final String? weightDate;
  final int? reminderWeeksBeforeEnd;
  final String? photoPath;

  static String _toDateStr(DateTime? d) =>
      d == null ? '' : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  factory DolipranePrescriptionModel.fromMap(Map<String, Object?> map) {
    return DolipranePrescriptionModel(
      id: (map['id'] as int?) ?? 0,
      childId: (map['child_id'] as int?) ?? 0,
      startDate: (map['start_date'] as String?) ?? '',
      endDate: (map['end_date'] as String?) ?? '',
      prescriptionDate: map['prescription_date'] as String?,
      childWeightKg: (map['child_weight_kg'] as num?)?.toDouble(),
      weightDate: map['weight_date'] as String?,
      reminderWeeksBeforeEnd: map['reminder_weeks_before_end'] as int?,
      photoPath: map['photo_path'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id == 0 ? null : id,
      'child_id': childId,
      'start_date': startDate,
      'end_date': endDate,
      'prescription_date': prescriptionDate,
      'child_weight_kg': childWeightKg,
      'weight_date': weightDate,
      'reminder_weeks_before_end': reminderWeeksBeforeEnd,
      'photo_path': photoPath,
    };
  }

  DolipranePrescription toEntity() {
    return DolipranePrescription(
      id: id,
      childId: childId,
      startDate: _parseDate(startDate) ?? DateTime.now(),
      endDate: _parseDate(endDate) ?? DateTime.now(),
      prescriptionDate: _parseDate(prescriptionDate),
      childWeightKg: childWeightKg,
      weightDate: _parseDate(weightDate),
      reminderWeeksBeforeEnd: reminderWeeksBeforeEnd,
      photoPath: photoPath,
    );
  }

  static DolipranePrescriptionModel fromEntity(DolipranePrescription e) {
    return DolipranePrescriptionModel(
      id: e.id,
      childId: e.childId,
      startDate: _toDateStr(e.startDate),
      endDate: _toDateStr(e.endDate),
      prescriptionDate: e.prescriptionDate != null ? _toDateStr(e.prescriptionDate) : null,
      childWeightKg: e.childWeightKg,
      weightDate: e.weightDate != null ? _toDateStr(e.weightDate) : null,
      reminderWeeksBeforeEnd: e.reminderWeeksBeforeEnd,
      photoPath: e.photoPath,
    );
  }
}
