class ChallanResponse {
  final int id;
  final String fullName;
  final String contactNumber;
  final int challanTypeId;
  final String challanName;
  final double fineAmount;
  final String description;
  final String wardNumber;
  final double latitude;
  final double longitude;
  final int inspectorProfileId;
  List<String> imageUrls;
  int imageCount;
  final String createdAt;
  final String updatedAt;

  ChallanResponse({
    required this.id,
    required this.fullName,
    required this.contactNumber,
    required this.challanTypeId,
    required this.challanName,
    required this.fineAmount,
    required this.description,
    required this.wardNumber,
    required this.latitude,
    required this.longitude,
    required this.inspectorProfileId,
    required this.imageUrls,
    required this.imageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getter for backward compatibility
  int get challanId => id;

  // Getters for UI compatibility (matching old Map structure)
  String get name => fullName;
  String get rule => challanName;
  String get amount => fineAmount.toString();
  String get mobile => contactNumber;
  String get notes => description;

  factory ChallanResponse.fromJson(Map<String, dynamic> json) {
    return ChallanResponse(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      fullName: json['full_name'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      challanTypeId: json['challan_type_id'] is int
          ? json['challan_type_id']
          : int.tryParse('${json['challan_type_id']}') ?? 0,
      challanName: json['challan_name'] ?? '',
      fineAmount: json['fine_amount'] is num
          ? (json['fine_amount'] as num).toDouble()
          : double.tryParse('${json['fine_amount']}') ?? 0.0,
      description: json['description'] ?? '',
      wardNumber: json['ward_number'] ?? '',
      latitude: json['latitude'] is num
          ? (json['latitude'] as num).toDouble()
          : double.tryParse('${json['latitude']}') ?? 0.0,
      longitude: json['longitude'] is num
          ? (json['longitude'] as num).toDouble()
          : double.tryParse('${json['longitude']}') ?? 0.0,
      inspectorProfileId: json['inspector_profile_id'] is int
          ? json['inspector_profile_id']
          : int.tryParse('${json['inspector_profile_id']}') ?? 0,
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageCount: json['image_count'] is int
          ? json['image_count']
          : int.tryParse('${json['image_count']}') ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'contact_number': contactNumber,
      'challan_type_id': challanTypeId,
      'challan_name': challanName,
      'fine_amount': fineAmount,
      'description': description,
      'ward_number': wardNumber,
      'latitude': latitude,
      'longitude': longitude,
      'inspector_profile_id': inspectorProfileId,
      'image_urls': imageUrls,
      'image_count': imageCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
