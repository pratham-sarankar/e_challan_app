import 'dart:async';

import 'package:flutter/services.dart';

/// Dart API for Vizpay ICICI Verifone Flutter plugin.
/// Currently supports **SALE** transaction only.
class VizpayFlutter {
  static const MethodChannel _channel = MethodChannel('vizpay_flutter');

  /// Starts a SALE transaction.
  ///
  /// Required:
  /// - [amount] : Transaction amount in decimal format (e.g. "500.00")
  /// - [billNumber] : Unique bill number for the transaction
  /// - [sourceId] : Merchant/source ID (provided by backend or ICICI)
  ///
  /// Optional:
  /// - [tipAmount] : Tip amount in decimal format (default: "")
  /// - [printFlag] : "1" to print customer slip, "0" to skip printing (default: "1")
  ///
  /// Returns a map like:
  /// ```json
  /// {
  ///   "RESPONSE_TYPE": "SALE",
  ///   "STATUS_CODE": "00",
  ///   "STATUS_MSG": "Approved",
  ///   "RECEIPT_DATA": "{...}"
  /// }
  /// ```
  static Future<Map<String, dynamic>?> startSaleTransaction({
    required String amount,
    required String billNumber,
    required String sourceId,
    String tipAmount = "",
    bool printFlag = true,
  }) async {
    final result = await _channel.invokeMethod('startSaleTransaction', {
      'amount': amount,
      'billNumber': billNumber,
      'sourceId': sourceId,
      'tipAmount': tipAmount,
      'printFlag': printFlag ? "1" : "0",
    });

    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }
}
