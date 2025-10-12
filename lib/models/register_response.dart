class RegisterResponse {
  final int userId;
  final String username;
  final String email;
  final String role;

  RegisterResponse({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse('${json['user_id']}') ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'role': role,
    };
  }
}
