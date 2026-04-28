enum UserRole {
  admin('Admin'),
  doctor('Doctor'),
  student('Student'),
  pharmacist('Pharmacist');

  const UserRole(this.label);
  final String label;
}
