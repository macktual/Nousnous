import 'parent.dart';
import 'weekly_pattern.dart';

class Child {
  const Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.contractStartDate,
    required this.contractEndDate,
    required this.isArchived,
    required this.photoPath,
    required this.parents,
    required this.weeklyPatterns,
    this.currentPatternId,
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
  final List<ParentInfo> parents;
  final List<WeeklyPattern> weeklyPatterns;
  final int? currentPatternId;
  /// Motif de départ (complété à l'archivage)
  final String? particularitesFinContrat;
  /// Vacances scolaires : oui / non
  final bool? vacancesScolaires;
  /// Particularités d'accueil
  final String? particularitesAccueil;
  /// Schéma vaccinal DTP/Hib/Hépatite B : 'hexavalent' (INFANRIX HEXA, Hexyon, Vaxelis) ou 'separate' (Hib + Hépatite B séparés).
  final String? vaccinationScheme;
  /// Signature saisie lors de l'archivage (utilisée pour la déclaration arrivée/départ).
  final String? archiveSignaturePath;

  Child copyWith({
    int? id,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    bool? isArchived,
    String? photoPath,
    List<ParentInfo>? parents,
    List<WeeklyPattern>? weeklyPatterns,
    int? currentPatternId,
    String? particularitesFinContrat,
    bool? vacancesScolaires,
    String? particularitesAccueil,
    String? vaccinationScheme,
    String? archiveSignaturePath,
  }) {
    return Child(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      isArchived: isArchived ?? this.isArchived,
      photoPath: photoPath ?? this.photoPath,
      parents: parents ?? this.parents,
      weeklyPatterns: weeklyPatterns ?? this.weeklyPatterns,
      currentPatternId: currentPatternId ?? this.currentPatternId,
      particularitesFinContrat: particularitesFinContrat ?? this.particularitesFinContrat,
      vacancesScolaires: vacancesScolaires ?? this.vacancesScolaires,
      particularitesAccueil: particularitesAccueil ?? this.particularitesAccueil,
      vaccinationScheme: vaccinationScheme ?? this.vaccinationScheme,
      archiveSignaturePath: archiveSignaturePath ?? this.archiveSignaturePath,
    );
  }
}

