class Assistant {
  const Assistant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.approvalNumber,
    required this.approvalDate,
    this.civility,
    this.postalCode,
    this.city,
    this.phone,
    this.email,
    this.agreementMaxChildren,
    this.accessCode,
    this.floor,
    this.signaturePath,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String address;
  final String approvalNumber;
  final DateTime approvalDate;
  /// Civilité : "Mme" ou "M."
  final String? civility;
  final String? postalCode;
  final String? city;
  final String? phone;
  final String? email;
  /// Nombre d'enfants pour l'agrément (1 à 4).
  final int? agreementMaxChildren;
  /// Code d'accès (ex. digicode).
  final String? accessCode;
  /// Étage.
  final String? floor;
  /// Chemin vers l'image de la signature (utilisée dans les déclarations arrivée/départ).
  final String? signaturePath;

  Assistant copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? address,
    String? approvalNumber,
    DateTime? approvalDate,
    String? civility,
    String? postalCode,
    String? city,
    String? phone,
    String? email,
    int? agreementMaxChildren,
    String? accessCode,
    String? floor,
    String? signaturePath,
  }) {
    return Assistant(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      approvalNumber: approvalNumber ?? this.approvalNumber,
      approvalDate: approvalDate ?? this.approvalDate,
      civility: civility ?? this.civility,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      agreementMaxChildren: agreementMaxChildren ?? this.agreementMaxChildren,
      accessCode: accessCode ?? this.accessCode,
      floor: floor ?? this.floor,
      signaturePath: signaturePath ?? this.signaturePath,
    );
  }
}

