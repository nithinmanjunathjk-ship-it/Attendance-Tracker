class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String? college;
  final String? semester;
  final String? section;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.college,
    this.semester,
    this.section,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      college: json['college'] as String?,
      semester: json['semester'] as String?,
      section: json['section'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'college': college,
        'semester': semester,
        'section': section,
      };

  ProfileModel copyWith({
    String? fullName,
    String? college,
    String? semester,
    String? section,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      college: college ?? this.college,
      semester: semester ?? this.semester,
      section: section ?? this.section,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
