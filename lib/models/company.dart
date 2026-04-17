class Company {
  String id;
  String name;
  String contact;
  String email;
  String? address;

  Company({
    required this.id,
    required this.name,
    required this.contact,
    required this.email,
    this.address,
  });
}
