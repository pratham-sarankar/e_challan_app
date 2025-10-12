/// Payment-related data models for ICICI POS integration
/// Following clean architecture principles with clear separation of concerns
library;

/// ICICI POS Request model for payment transactions
class PosRequest {
  final String amount;
  final String tipAmount;
  final String tranId;
  final String tranType;
  final String billNumber;
  final String sourceId;
  final String printFlag;
  final Map<String, String> udf;

  const PosRequest({
    required this.amount,
    this.tipAmount = '0.00',
    this.tranId = '',
    required this.tranType,
    required this.billNumber,
    required this.sourceId,
    this.printFlag = '1',
    Map<String, String>? udf,
  }) : udf =
           udf ??
           const {'UDF1': '', 'UDF2': '', 'UDF3': '', 'UDF4': '', 'UDF5': ''};

  /// Convert to JSON format for native platform communication
  Map<String, dynamic> toJson() {
    return {
      'AMOUNT': amount,
      'TIP_AMOUNT': tipAmount,
      'TRAN_ID': tranId,
      'TRAN_TYPE': tranType,
      'BILL_NUMBER': billNumber,
      'SOURCE_ID': sourceId,
      'PRINT_FLAG': printFlag,
      'UDF1': udf['UDF1'],
      'UDF2': udf['UDF2'],
      'UDF3': udf['UDF3'],
      'UDF4': udf['UDF4'],
      'UDF5': udf['UDF5'],
    };
  }

  /// Create a copy with updated values
  PosRequest copyWith({
    String? amount,
    String? tipAmount,
    String? tranId,
    String? tranType,
    String? billNumber,
    String? sourceId,
    String? printFlag,
    Map<String, String>? udf,
  }) {
    return PosRequest(
      amount: amount ?? this.amount,
      tipAmount: tipAmount ?? this.tipAmount,
      tranId: tranId ?? this.tranId,
      tranType: tranType ?? this.tranType,
      billNumber: billNumber ?? this.billNumber,
      sourceId: sourceId ?? this.sourceId,
      printFlag: printFlag ?? this.printFlag,
      udf: udf ?? this.udf,
    );
  }
}

/// ICICI POS Response model for handling payment responses
/// ICICI POS Response model for handling payment responses
class PosResponse {
  final String statusCode;
  final String statusMessage;
  final Map<String, dynamic>? receiptData;
  final Map<String, dynamic>? rawResponse;
  final DateTime timestamp;

  PosResponse({
    // Changed from const PosResponse
    required this.statusCode,
    required this.statusMessage,
    this.receiptData,
    this.rawResponse,
    DateTime? timestamp,
  }) : timestamp =
           timestamp ?? DateTime.now(); // Simplified timestamp initialization

  /// Check if the payment was successful
  bool get isSuccess => statusCode == '00';

  /// Get formatted status message
  String get formattedMessage {
    final emoji = isSuccess ? '✅' : '❌';
    return '$emoji $statusCode - $statusMessage';
  }

  /// Create from JSON response
  factory PosResponse.fromJson(Map<String, dynamic> json) {
    return PosResponse(
      statusCode: json['STATUS_CODE']?.toString() ?? 'ERR',
      statusMessage: json['STATUS_MSG']?.toString() ?? 'Unknown Error',
      receiptData: json['RECEIPT_DATA'] != null
          ? Map<String, dynamic>.from(json['RECEIPT_DATA'])
          : null,
      rawResponse: json,
      // Consider if you want to parse a timestamp from JSON here as well,
      // or if DateTime.now() is always appropriate for fromJson.
      // If a timestamp comes from the JSON, you'd parse it similarly to
      // PaymentTransaction.fromJson
    );
  }

  /// Create error response
  factory PosResponse.error(String message, {String? code}) {
    return PosResponse(
      statusCode: code ?? 'ERR',
      statusMessage: message,
      // timestamp will default to DateTime.now()
    );
  }

  // If you need a toJson method for PosResponse, you would add it here:
  Map<String, dynamic> toJson() {
    return {
      'STATUS_CODE': statusCode,
      'STATUS_MSG': statusMessage,
      'RECEIPT_DATA': receiptData,
      'RAW_RESPONSE': rawResponse, // Assuming you want to serialize this too
      'TIMESTAMP': timestamp.toIso8601String(),
    };
  }
}

/// Payment transaction model for challan payments
class PaymentTransaction {
  final String transactionId;
  final String challanId;
  final String amount;
  final String paymentMethod;
  final String status;
  final DateTime? timestamp;
  final PosResponse? posResponse;
  final String? receiptNumber;

  const PaymentTransaction({
    required this.transactionId,
    required this.challanId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.timestamp,
    this.posResponse,
    this.receiptNumber,
  });

  /// Check if payment is completed
  bool get isCompleted => status == 'COMPLETED';

  /// Check if payment failed
  bool get isFailed => status == 'FAILED';

  /// Check if payment is pending
  bool get isPending => status == 'PENDING';

  /// Create a copy with updated values
  PaymentTransaction copyWith({
    String? transactionId,
    String? challanId,
    String? amount,
    String? paymentMethod,
    String? status,
    DateTime? timestamp,
    PosResponse? posResponse,
    String? receiptNumber,
  }) {
    return PaymentTransaction(
      transactionId: transactionId ?? this.transactionId,
      challanId: challanId ?? this.challanId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      posResponse: posResponse ?? this.posResponse,
      receiptNumber: receiptNumber ?? this.receiptNumber,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'challanId': challanId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'timestamp': timestamp,
      'posResponse': posResponse?.toJson(),
      'receiptNumber': receiptNumber,
    };
  }

  /// Create from JSON
  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      transactionId: json['transactionId'] ?? '',
      challanId: json['challanId'] ?? '',
      amount: json['amount'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      posResponse: json['posResponse'] != null
          ? PosResponse.fromJson(json['posResponse'])
          : null,
      receiptNumber: json['receiptNumber'],
    );
  }
}

/// Payment configuration model
class PaymentConfig {
  final String sourceId;
  final bool enablePrinting;
  final bool enableVoid;
  final List<String> supportedPaymentMethods;

  const PaymentConfig({
    required this.sourceId,
    this.enablePrinting = true,
    this.enableVoid = true,
    this.supportedPaymentMethods = const ['CARD', 'UPI', 'CASH'],
  });

  /// Default configuration for Municipal E-Challan
  static const PaymentConfig defaultConfig = PaymentConfig(
    sourceId: '100000000004645', // ICICI source ID for municipal payments
    enablePrinting: true,
    enableVoid: true,
    supportedPaymentMethods: ['CARD', 'UPI', 'CASH'],
  );
}
