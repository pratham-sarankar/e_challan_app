class User {
  final String fullName;
  final String mobileNumber;

  User({required this.fullName, required this.mobileNumber});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(fullName: json['fullName'], mobileNumber: json['mobileNumber']);
  }

  Map<String, dynamic> toJson() {
    return {'fullName': fullName, 'mobileNumber': mobileNumber};
  }
}
