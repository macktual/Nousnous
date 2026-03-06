import '../../domain/entities/assistant.dart';

class AssistantModel extends Assistant {
  const AssistantModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.address,
    required super.approvalNumber,
    required super.approvalDate,
    super.civility,
    super.postalCode,
    super.city,
    super.phone,
    super.email,
    super.agreementMaxChildren,
    super.accessCode,
    super.floor,
    super.signaturePath,
  });

  factory AssistantModel.fromMap(Map<String, Object?> map) {
    final raw = map['agreement_max_children'];
    final agreementMaxChildren = raw == null ? null : (raw is int ? raw : int.tryParse(raw.toString()));
    return AssistantModel(
      id: (map['id'] as int?) ?? 1,
      firstName: (map['first_name'] as String?) ?? '',
      lastName: (map['last_name'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      approvalNumber: (map['approval_number'] as String?) ?? '',
      approvalDate: DateTime.parse((map['approval_date'] as String?) ?? DateTime.now().toIso8601String()),
      civility: map['civility'] as String?,
      postalCode: map['postal_code'] as String?,
      city: map['city'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      agreementMaxChildren: agreementMaxChildren != null && agreementMaxChildren >= 1 && agreementMaxChildren <= 4 ? agreementMaxChildren : null,
      accessCode: map['access_code'] as String?,
      floor: map['floor'] as String?,
      signaturePath: map['signature_path'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'approval_number': approvalNumber,
      'approval_date': approvalDate.toIso8601String(),
      'civility': civility,
      'postal_code': postalCode,
      'city': city,
      'phone': phone,
      'email': email,
      'agreement_max_children': agreementMaxChildren,
      'access_code': accessCode,
      'floor': floor,
      'signature_path': signaturePath,
    };
  }
}

