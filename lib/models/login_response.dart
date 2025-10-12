class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String username;
  final String role;
  final int expiresIn;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.username,
    required this.role,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? '',
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse('${json['user_id']}') ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? '',
      expiresIn: json['expires_in'] is int
          ? json['expires_in']
          : int.tryParse('${json['expires_in']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user_id': userId,
      'username': username,
      'role': role,
      'expires_in': expiresIn,
    };
  }
}
