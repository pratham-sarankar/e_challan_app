/// Payment service for ICICI POS integration
/// Handles communication with native ICICI POS application
/// Following clean architecture with dependency injection support
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/payment_models.dart';

/// Interface for payment service - enables easy testing and mocking
abstract class IPaymentService {
  Future<PosResponse> processPayment(PosRequest request);
  Future<PosResponse> voidPayment(String billNumber);
  Future<PosResponse> checkTransactionStatus(String transactionId);
  Future<bool> isPosAppInstalled();
}

/// ICICI POS Service implementation
/// Handles native platform communication for payment processing
class PaymentService implements IPaymentService {
  static const MethodChannel _channel = MethodChannel('vizpay/pos');

  // ICICI POS Constants
  static const String _packageName = "com.icici.viz.verifone";
  static const String _uniqueKey = "123456";

  // Transaction Types
  static const String _sale = "SALE";
  static const String _void = "VOID";
  static const String _settlement = "SETTLEMENT";
  static const String _bqr = "BQR";
  static const String _qr = "QR";
  static const String _cashAtPos = "CASHATPOS";
  static const String _preAuth = "PREAUTH";
  static const String _authCompletion = "AUTHCOMPLETION";
  static const String _transactionStatusCheck = "TRANSACTION_STATUS_CHECK";
  static const String _anyReceipt = "ANYRECEIPT";
  static const String _lastReceipt = "LASTRECEIPT";
  static const String _detailReport = "DETAILREPORT";

  // Result Codes
  static const int _saleResultCode = 101;
  static const int _voidResultCode = 102;
  static const int _qrResultCode = 103;
  static const int _cashAtPosResultCode = 104;
  static const int _preAuthResultCode = 105;
  static const int _authCompletionResultCode = 106;
  static const int _settlementResultCode = 107;
  static const int _checkTxnStatusResultCode = 108;
  static const int _anyReceiptResultCode = 109;
  static const int _lastReceiptResultCode = 110;
  static const int _detailReportResultCode = 111;

  /// Process payment using ICICI POS
  /// [request] - Payment request with amount, bill number, etc.
  /// Returns [PosResponse] with transaction result
  @override
  Future<PosResponse> processPayment(PosRequest request) async {
    try {
      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _sale,
        'DATA': jsonEncode(request.toJson()),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Process QR payment
  /// [amount] - Payment amount
  /// [billNumber] - Bill number for transaction
  /// Returns [PosResponse] with QR result
  Future<PosResponse> processQrPayment(String amount, String billNumber) async {
    try {
      final requestData = {
        'AMOUNT': amount, // e.g. "500.00"
        'BILL_NUMBER': billNumber, // e.g. "xyz123"
        'TRAN_TYPE': 'QR', // fixed value
        'SOURCE_ID': _uniqueKey, // your unique identifier
        'PRINT_FLAG': '1', // 1 = print, 0 = no print
        'TIP_AMOUNT': '0.00', // optional, defaulting to 0
      };

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _qr, // make sure _qr == "QR"
        'DATA': jsonEncode(requestData),
        'INTENT_REQUEST_CODE': 103, // required as per spec
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Void a previous payment transaction
  /// [billNumber] - Bill number of transaction to void
  /// Returns [PosResponse] with void result
  @override
  Future<PosResponse> voidPayment(String billNumber) async {
    try {
      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _void,
        'DATA': jsonEncode({'BILL_NUMBER': billNumber}),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Check transaction status
  /// [transactionId] - Transaction ID to check
  /// Returns [PosResponse] with transaction status
  @override
  Future<PosResponse> checkTransactionStatus(String transactionId) async {
    try {
      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _transactionStatusCheck,
        'DATA': jsonEncode({'TRAN_ID': transactionId}),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Check if ICICI POS app is installed
  /// Returns [bool] indicating if POS app is available
  @override
  Future<bool> isPosAppInstalled() async {
    try {
      if (Platform.isAndroid) {
        // For Android, we can check if the app is installed
        // This would require platform-specific implementation
        return true; // Assuming installed for now
      } else {
        // iOS implementation would go here
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Process BQR payment
  /// [amount] - Payment amount
  /// [billNumber] - Bill number for transaction
  /// Returns [PosResponse] with BQR result
  Future<PosResponse> processBqrPayment(
    String amount,
    String billNumber,
  ) async {
    try {
      final requestData = {
        'AMOUNT': amount,
        'BILL_NUMBER': billNumber,
        'SOURCE_ID': _uniqueKey,
      };

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _bqr,
        'DATA': jsonEncode(requestData),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Process Cash at POS payment
  /// [amount] - Payment amount
  /// [billNumber] - Bill number for transaction
  /// Returns [PosResponse] with Cash at POS result
  Future<PosResponse> processCashAtPosPayment(
    String amount,
    String billNumber,
  ) async {
    try {
      final requestData = {
        'AMOUNT': amount,
        'BILL_NUMBER': billNumber,
        'SOURCE_ID': _uniqueKey,
      };

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _cashAtPos,
        'DATA': jsonEncode(requestData),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Process Pre-Auth payment
  /// [amount] - Payment amount
  /// [billNumber] - Bill number for transaction
  /// Returns [PosResponse] with Pre-Auth result
  Future<PosResponse> processPreAuthPayment(
    String amount,
    String billNumber,
  ) async {
    try {
      final requestData = {
        'AMOUNT': amount,
        'BILL_NUMBER': billNumber,
        'SOURCE_ID': _uniqueKey,
      };

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _preAuth,
        'DATA': jsonEncode(requestData),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Process Auth Completion
  /// [amount] - Payment amount
  /// [billNumber] - Bill number for transaction
  /// Returns [PosResponse] with Auth Completion result
  Future<PosResponse> processAuthCompletion(
    String amount,
    String billNumber,
  ) async {
    try {
      final requestData = {
        'AMOUNT': amount,
        'BILL_NUMBER': billNumber,
        'SOURCE_ID': _uniqueKey,
      };

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _authCompletion,
        'DATA': jsonEncode(requestData),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Process Settlement
  /// Returns [PosResponse] with Settlement result
  Future<PosResponse> processSettlement() async {
    try {
      final requestData = {'SOURCE_ID': _uniqueKey};

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _settlement,
        'DATA': jsonEncode(requestData),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Get Last Receipt
  /// Returns [PosResponse] with Last Receipt result
  Future<PosResponse> getLastReceipt() async {
    try {
      final requestData = {'SOURCE_ID': _uniqueKey};

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _lastReceipt,
        'DATA': jsonEncode(requestData),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Get Any Receipt
  /// [invoiceNumber] - Invoice number to retrieve
  /// Returns [PosResponse] with Any Receipt result
  Future<PosResponse> getAnyReceipt(String invoiceNumber) async {
    try {
      final requestData = {
        'INVOICE_NUMBER': invoiceNumber,
        'SOURCE_ID': _uniqueKey,
      };

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _anyReceipt,
        'DATA': jsonEncode(requestData),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Get Detail Report
  /// Returns [PosResponse] with Detail Report result
  Future<PosResponse> getDetailReport() async {
    try {
      final requestData = {'SOURCE_ID': _uniqueKey};

      final result = await _channel.invokeMethod('invokePos', {
        'REQUEST_TYPE': _detailReport,
        'DATA': jsonEncode(requestData),
      });

      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        return PosResponse.fromJson(response);
      } else {
        return PosResponse.error('Unexpected response type from native');
      }
    } on PlatformException catch (e) {
      return PosResponse.error(
        'Platform error: ${e.message ?? 'Unknown error'}',
        code: 'PLATFORM_ERROR',
      );
    } catch (e) {
      return PosResponse.error(
        'Unexpected error: $e',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Generate random transaction ID
  static String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN_$timestamp$random';
  }

  /// Generate bill number for challan
  static String generateBillNumber(String challanId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'CHALLAN_${challanId}_$timestamp';
  }
}

/// Mock payment service for testing
/// Implements [IPaymentService] with simulated responses
class MockPaymentService implements IPaymentService {
  final bool shouldSucceed;
  final Duration delay;

  const MockPaymentService({
    this.shouldSucceed = true,
    this.delay = const Duration(seconds: 2),
  });

  @override
  Future<PosResponse> processPayment(PosRequest request) async {
    await Future.delayed(delay);

    if (shouldSucceed) {
      return PosResponse.fromJson({
        'STATUS_CODE': '00',
        'STATUS_MSG': 'SUCCESS',
        'RECEIPT_DATA': {
          'billNumber': request.billNumber,
          'InvoiceNr': 'INV_${DateTime.now().millisecondsSinceEpoch}',
          'SaleAmt': request.amount,
          'TipAmount': request.tipAmount,
          'NameOnCard': 'TEST CARD HOLDER',
        },
      });
    } else {
      return PosResponse.error('Payment failed - insufficient funds');
    }
  }

  @override
  Future<PosResponse> voidPayment(String billNumber) async {
    await Future.delayed(delay);

    if (shouldSucceed) {
      return PosResponse.fromJson({
        'STATUS_CODE': '00',
        'STATUS_MSG': 'VOID SUCCESS',
      });
    } else {
      return PosResponse.error('Void failed - transaction not found');
    }
  }

  @override
  Future<PosResponse> checkTransactionStatus(String transactionId) async {
    await Future.delayed(delay);

    if (shouldSucceed) {
      return PosResponse.fromJson({
        'STATUS_CODE': '00',
        'STATUS_MSG': 'COMPLETED',
      });
    } else {
      return PosResponse.error('Transaction not found');
    }
  }

  @override
  Future<bool> isPosAppInstalled() async {
    return true;
  }
}

/// Payment service factory for dependency injection
class PaymentServiceFactory {
  static IPaymentService create({bool useMock = false}) {
    if (useMock) {
      return MockPaymentService();
    }
    return PaymentService();
  }
}
