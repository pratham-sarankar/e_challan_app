class ChallanType {
  final int id;
  final String typeName;
  final int fineAmount;
  final String description;
  final String isActive;
  final String createdAt;
  final String updatedAt;

  ChallanType({
    required this.id,
    required this.typeName,
    required this.fineAmount,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChallanType.fromJson(Map<String, dynamic> json) {
    // Robust parsing for numeric fields which may come as int, double, or string
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      final s = v.toString();
      // Handle floats in string form like '200.0'
      if (s.contains('.')) {
        final n = double.tryParse(s);
        if (n != null) return n.toInt();
      }
      return int.tryParse(s) ?? 0;
    }

    return ChallanType(
      id: parseInt(json['id']),
      typeName: json['type_name'] ?? '',
      fineAmount: parseInt(json['fine_amount']),
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type_name': typeName,
      'fine_amount': fineAmount,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
