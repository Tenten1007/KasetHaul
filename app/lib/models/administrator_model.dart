class AdministratorModel {
  final String administratorId;
  final String username;
  final String role;

  const AdministratorModel({
    required this.administratorId,
    required this.username,
    required this.role,
  });

  factory AdministratorModel.fromJson(Map<String, dynamic> json) => AdministratorModel(
        administratorId: json['administratorId'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
      );

  Map<String, dynamic> toJson() => {
        'administratorId': administratorId,
        'username': username,
        'role': role,
      };
}
