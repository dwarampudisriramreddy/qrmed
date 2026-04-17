class College {
  String id; // collegename@supreme.com
  String collegeCode; // 3-digit numeric code
  String name;
  String city;
  double? latitude;
  double? longitude;
  String type; // dental or medical
  String seats;
  String password;
  String? logoUrl; // New field for college logo URL

  College({
    required this.id,
    required this.collegeCode,
    required this.name,
    required this.city,
    this.latitude,
    this.longitude,
    required this.type,
    required this.seats,
    required this.password,
    this.logoUrl, // Initialize the new field
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      id: json['id'] as String,
      collegeCode: json['collegeCode'] as String? ?? '000',
      name: json['name'] as String,
      city: json['city'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      type: json['type'] as String,
      seats: json['seats'] as String,
      password: json['password'] as String,
      logoUrl: json['logoUrl'] as String?, // Deserialize logoUrl
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collegeCode': collegeCode,
      'name': name,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'seats': seats,
      'password': password,
      'logoUrl': logoUrl, // Serialize logoUrl
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is College && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
