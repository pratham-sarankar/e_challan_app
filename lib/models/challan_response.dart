class ChallanResponse {
  final int id;
  final int challanId;
  final String fullName;
  final String contactNumber;
  final String challanName;
  final int fineAmount;
  final int challanTypeId;
  final List<String> imageUrls;
  final int imageCount;
  final String createdAt;

  ChallanResponse({
    required this.id,
    required this.challanId,
    required this.fullName,
    required this.contactNumber,
    required this.challanName,
    required this.fineAmount,
    required this.challanTypeId,
    required this.imageUrls,
    required this.imageCount,
    required this.createdAt,
  });

  factory ChallanResponse.fromJson(Map<String, dynamic> json) {
    return ChallanResponse(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      challanId: json['challan_id'] is int
          ? json['challan_id']
          : int.tryParse('${json['challan_id']}') ?? 0,
      fullName: json['full_name'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      challanName: json['challan_name'] ?? '',
      fineAmount: json['fine_amount'] is int
          ? json['fine_amount']
          : int.tryParse('${json['fine_amount']}') ?? 0,
      challanTypeId: json['challan_type_id'] is int
          ? json['challan_type_id']
          : int.tryParse('${json['challan_type_id']}') ?? 0,
      imageUrls:
          (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageCount: json['image_count'] is int
          ? json['image_count']
          : int.tryParse('${json['image_count']}') ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challan_id': challanId,
      'full_name': fullName,
      'contact_number': contactNumber,
      'challan_name': challanName,
      'fine_amount': fineAmount,
      'challan_type_id': challanTypeId,
      'image_urls': imageUrls,
      'image_count': imageCount,
      'created_at': createdAt,
    };
  }
}
