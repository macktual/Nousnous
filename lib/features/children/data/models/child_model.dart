import 'package:intl/intl.dart';

import '../../domain/entities/child.dart';
import '../../domain/entities/parent.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/weekly_pattern.dart';

class ChildModel {
  const ChildModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.contractStartDate,
    required this.contractEndDate,
    required this.isArchived,
    required this.photoPath,
    required this.currentPatternId,
    this.particularitesFinContrat,
    this.vacancesScolaires,
    this.particularitesAccueil,
    this.vaccinationScheme,
    this.archiveSignaturePath,
  });

  final int id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final DateTime contractStartDate;
  final DateTime? contractEndDate;
  final bool isArchived;
  final String? photoPath;
  final int? currentPatternId;
  final String? particularitesFinContrat;
  final bool? vacancesScolaires;
  final String? particularitesAccueil;
  final String? vaccinationScheme;
  final String? archiveSignaturePath;

  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  factory ChildModel.fromMap(Map<String, Object?> map) {
    return ChildModel(
      id: (map['id'] as int?) ?? 0,
      firstName: (map['first_name'] as String?) ?? '',
      lastName: (map['last_name'] as String?) ?? '',
      birthDate: _parseDate(map['birth_date'] as String?),
      contractStartDate: _parseDate(map['contract_start_date'] as String?),
      contractEndDate: _parseNullableDate(map['contract_end_date'] as String?),
      isArchived: (map['is_archived'] as int?) == 1,
      photoPath: map['photo_path'] as String?,
      currentPatternId: map['current_pattern_id'] as int?,
      particularitesFinContrat: map['particularites_fin_contrat'] as String?,
      vacancesScolaires: _parseVacances(map['vacances_scolaires']),
      particularitesAccueil: map['particularites_accueil'] as String?,
      vaccinationScheme: map['vaccination_scheme'] as String?,
      archiveSignaturePath: map['archive_signature_path'] as String?,
    );
  }

  static bool? _parseVacances(dynamic v) {
    if (v == null) return null;
    if (v is int) return v == 1;
    return null;
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id == 0 ? null : id,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': _dateFormat.format(birthDate),
      'contract_start_date': _dateFormat.format(contractStartDate),
      'contract_end_date': contractEndDate == null ? null : _dateFormat.format(contractEndDate!),
      'is_archived': isArchived ? 1 : 0,
      'photo_path': photoPath,
      'current_pattern_id': currentPatternId,
      'particularites_fin_contrat': particularitesFinContrat,
      'vacances_scolaires': vacancesScolaires == null ? null : (vacancesScolaires! ? 1 : 0),
      'particularites_accueil': particularitesAccueil,
      'vaccination_scheme': vaccinationScheme,
      'archive_signature_path': archiveSignaturePath,
    };
  }

  Child toEntity({
    required List<ParentInfo> parents,
    required List<WeeklyPattern> patterns,
  }) {
    return Child(
      id: id,
      firstName: firstName,
      lastName: lastName,
      birthDate: birthDate,
      contractStartDate: contractStartDate,
      contractEndDate: contractEndDate,
      isArchived: isArchived,
      photoPath: photoPath,
      parents: parents,
      weeklyPatterns: patterns,
      currentPatternId: currentPatternId,
      particularitesFinContrat: particularitesFinContrat,
      vacancesScolaires: vacancesScolaires,
      particularitesAccueil: particularitesAccueil,
      vaccinationScheme: vaccinationScheme,
      archiveSignaturePath: archiveSignaturePath,
    );
  }

  static DateTime _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.now();
    }
    return _dateFormat.parse(value);
  }

  static DateTime? _parseNullableDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return _dateFormat.parse(value);
  }

  static ChildModel fromEntity(Child child) {
    return ChildModel(
      id: child.id,
      firstName: child.firstName,
      lastName: child.lastName,
      birthDate: child.birthDate,
      contractStartDate: child.contractStartDate,
      contractEndDate: child.contractEndDate,
      isArchived: child.isArchived,
      photoPath: child.photoPath,
      currentPatternId: child.currentPatternId,
      particularitesFinContrat: child.particularitesFinContrat,
      vacancesScolaires: child.vacancesScolaires,
      particularitesAccueil: child.particularitesAccueil,
      vaccinationScheme: child.vaccinationScheme,
      archiveSignaturePath: child.archiveSignaturePath,
    );
  }
}

class ParentModel {
  const ParentModel({
    required this.id,
    required this.childId,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.phone,
    required this.email,
    this.postalCode,
    this.city,
  });

  final int id;
  final int childId;
  final String role;
  final String firstName;
  final String lastName;
  final String address;
  final String phone;
  final String email;
  final String? postalCode;
  final String? city;

  ParentModel copyWith({
    int? id,
    int? childId,
    String? role,
    String? firstName,
    String? lastName,
    String? address,
    String? phone,
    String? email,
    String? postalCode,
    String? city,
  }) {
    return ParentModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
    );
  }

  factory ParentModel.fromMap(Map<String, Object?> map) {
    return ParentModel(
      id: (map['id'] as int?) ?? 0,
      childId: (map['child_id'] as int?) ?? 0,
      role: (map['role'] as String?) ?? 'parent1',
      firstName: (map['first_name'] as String?) ?? '',
      lastName: (map['last_name'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      postalCode: map['postal_code'] as String?,
      city: map['city'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id == 0 ? null : id,
      'child_id': childId,
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'phone': phone,
      'email': email,
      'postal_code': postalCode,
      'city': city,
    };
  }

  ParentInfo toEntity() {
    return ParentInfo(
      id: id,
      childId: childId,
      role: role,
      firstName: firstName,
      lastName: lastName,
      address: address,
      phone: phone,
      email: email,
      postalCode: postalCode,
      city: city,
    );
  }

  static ParentModel fromEntity(ParentInfo p) {
    return ParentModel(
      id: p.id,
      childId: p.childId,
      role: p.role,
      firstName: p.firstName,
      lastName: p.lastName,
      address: p.address,
      phone: p.phone,
      email: p.email,
      postalCode: p.postalCode,
      city: p.city,
    );
  }
}

class WeeklyPatternModel {
  const WeeklyPatternModel({
    required this.id,
    required this.childId,
    required this.name,
    required this.isActive,
    this.validFrom,
    this.validUntil,
  });

  final int id;
  final int childId;
  final String name;
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validUntil;

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static String? _formatDate(DateTime? d) => d == null ? null : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  WeeklyPatternModel copyWith({
    int? id,
    int? childId,
    String? name,
    bool? isActive,
    DateTime? validFrom,
    DateTime? validUntil,
  }) {
    return WeeklyPatternModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
    );
  }

  factory WeeklyPatternModel.fromMap(Map<String, Object?> map) {
    return WeeklyPatternModel(
      id: (map['id'] as int?) ?? 0,
      childId: (map['child_id'] as int?) ?? 0,
      name: (map['name'] as String?) ?? '',
      isActive: (map['is_active'] as int?) == 1,
      validFrom: _parseDate(map['valid_from'] as String?),
      validUntil: _parseDate(map['valid_until'] as String?),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id == 0 ? null : id,
      'child_id': childId,
      'name': name,
      'is_active': isActive ? 1 : 0,
      'valid_from': _formatDate(validFrom),
      'valid_until': _formatDate(validUntil),
    };
  }

  WeeklyPattern toEntity(List<ScheduleEntry> entries) {
    return WeeklyPattern(
      id: id,
      childId: childId,
      name: name,
      isActive: isActive,
      entries: entries,
      validFrom: validFrom,
      validUntil: validUntil,
    );
  }

  static WeeklyPatternModel fromEntity(WeeklyPattern pattern) {
    return WeeklyPatternModel(
      id: pattern.id,
      childId: pattern.childId,
      name: pattern.name,
      isActive: pattern.isActive,
      validFrom: pattern.validFrom,
      validUntil: pattern.validUntil,
    );
  }
}

class ScheduleEntryModel {
  const ScheduleEntryModel({
    required this.id,
    required this.patternId,
    required this.weekday,
    required this.arrivalTime,
    required this.departureTime,
  });

  final int id;
  final int patternId;
  final int weekday;
  final String? arrivalTime;
  final String? departureTime;

  ScheduleEntryModel copyWith({
    int? id,
    int? patternId,
    int? weekday,
    String? arrivalTime,
    String? departureTime,
  }) {
    return ScheduleEntryModel(
      id: id ?? this.id,
      patternId: patternId ?? this.patternId,
      weekday: weekday ?? this.weekday,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
    );
  }

  factory ScheduleEntryModel.fromMap(Map<String, Object?> map) {
    return ScheduleEntryModel(
      id: (map['id'] as int?) ?? 0,
      patternId: (map['pattern_id'] as int?) ?? 0,
      weekday: (map['weekday'] as int?) ?? 1,
      arrivalTime: map['arrival_time'] as String?,
      departureTime: map['departure_time'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id == 0 ? null : id,
      'pattern_id': patternId,
      'weekday': weekday,
      'arrival_time': arrivalTime,
      'departure_time': departureTime,
    };
  }

  ScheduleEntry toEntity() {
    return ScheduleEntry(
      id: id,
      patternId: patternId,
      weekday: weekday,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
    );
  }

  static ScheduleEntryModel fromEntity(ScheduleEntry e) {
    return ScheduleEntryModel(
      id: e.id,
      patternId: e.patternId,
      weekday: e.weekday,
      arrivalTime: e.arrivalTime,
      departureTime: e.departureTime,
    );
  }
}

