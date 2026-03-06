class ParentInfo {
  const ParentInfo({
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
  final String role; // 'parent1' ou 'parent2'
  final String firstName;
  final String lastName;
  final String address;
  final String phone;
  final String email;
  final String? postalCode;
  final String? city;
}

