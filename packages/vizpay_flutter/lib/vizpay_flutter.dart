import 'dart:async';

import 'package:flutter/services.dart';

/// Dart API for Vizpay ICICI Flutter plugin.
/// Currently supports **SALE** and **UPI** transaction.
/// 
/// The plugin supports different ICICI payment apps based on the build flavor:
/// - Development flavor: Uses com.icici.viz.verifone
/// - Production flavor: Uses com.icici.viz.pax
/// 
/// Call [setPaymentAppPackage] before making any transactions to specify
/// which payment app package to use.
class VizpayFlutter {
  static const MethodChannel _channel = MethodChannel('vizpay_flutter');

  /// Sets the payment app package name to use for transactions.
  /// 
  /// This should be called during app initialization to configure which
  /// ICICI payment app to use:
  /// - For development: "com.icici.viz.verifone"
  /// - For production: "com.icici.viz.pax"
  /// 
  /// Example:
  /// ```dart
  /// await VizpayFlutter.setPaymentAppPackage("com.icici.viz.verifone");
  /// ```
  static Future<bool> setPaymentAppPackage(String packageName) async {
    try {
      final result = await _channel.invokeMethod('setPaymentAppPackage', packageName);
      return result == true;
    } catch (e) {
      return false;
    }
  }

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

  static Future<Map<String, dynamic>?> startUpiTransaction({
    required String amount,
    required String billNumber,
    required String sourceId,
    String tipAmount = "",
    bool printFlag = true,
  }) async {
    final result = await _channel.invokeMethod('startUpiTransaction', {
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
