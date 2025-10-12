/// Payment BLoC Events
/// Defines all possible events that can be triggered in the payment flow
/// Following BLoC pattern for clean state management
library;

import '../../models/payment_models.dart';

/// Base class for all payment events
abstract class PaymentEvent {
  const PaymentEvent();
}

/// Event to initialize payment process for a challan
class PaymentInitializeEvent extends PaymentEvent {
  final String challanId;
  final String amount;
  final String violatorName;
  final String violatorMobile;

  const PaymentInitializeEvent({
    required this.challanId,
    required this.amount,
    required this.violatorName,
    required this.violatorMobile,
  });

  @override
  String toString() =>
      'PaymentInitializeEvent(challanId: $challanId, amount: $amount)';
}

/// Event to process payment using ICICI POS
class PaymentProcessEvent extends PaymentEvent {
  final PosRequest posRequest;

  const PaymentProcessEvent({required this.posRequest});

  @override
  String toString() =>
      'PaymentProcessEvent(billNumber: ${posRequest.billNumber}, amount: ${posRequest.amount})';
}

/// Event to process UPI payment via QR code
class PaymentUpiEvent extends PaymentEvent {
  final String amount;
  final String challanId;
  final String violatorName;

  const PaymentUpiEvent({
    required this.amount,
    required this.challanId,
    required this.violatorName,
  });

  @override
  String toString() =>
      'PaymentUpiEvent(amount: $amount, challanId: $challanId)';
}

/// Event to process cash payment
class PaymentCashEvent extends PaymentEvent {
  final String amount;
  final String challanId;
  final String violatorName;

  const PaymentCashEvent({
    required this.amount,
    required this.challanId,
    required this.violatorName,
  });

  @override
  String toString() =>
      'PaymentCashEvent(amount: $amount, challanId: $challanId)';
}

/// Event to void a payment transaction
class PaymentVoidEvent extends PaymentEvent {
  final String billNumber;
  final String reason;

  const PaymentVoidEvent({
    required this.billNumber,
    this.reason = 'Voided by officer',
  });

  @override
  String toString() =>
      'PaymentVoidEvent(billNumber: $billNumber, reason: $reason)';
}

/// Event to check payment status
class PaymentStatusCheckEvent extends PaymentEvent {
  final String transactionId;

  const PaymentStatusCheckEvent({required this.transactionId});

  @override
  String toString() => 'PaymentStatusCheckEvent(transactionId: $transactionId)';
}

/// Event to generate payment receipt
class PaymentReceiptEvent extends PaymentEvent {
  final PaymentTransaction transaction;

  const PaymentReceiptEvent({required this.transaction});

  @override
  String toString() =>
      'PaymentReceiptEvent(transactionId: ${transaction.transactionId})';
}

/// Event to reset payment state
class PaymentResetEvent extends PaymentEvent {
  const PaymentResetEvent();

  @override
  String toString() => 'PaymentResetEvent()';
}

/// Event to update payment configuration
class PaymentConfigUpdateEvent extends PaymentEvent {
  final PaymentConfig config;

  const PaymentConfigUpdateEvent({required this.config});

  @override
  String toString() => 'PaymentConfigUpdateEvent(sourceId: ${config.sourceId})';
}

/// Event to handle payment errors
class PaymentErrorEvent extends PaymentEvent {
  final String error;
  final String? code;

  const PaymentErrorEvent({required this.error, this.code});

  @override
  String toString() => 'PaymentErrorEvent(error: $error, code: $code)';
}

/// Event to process BQR payment
class PaymentBqrEvent extends PaymentEvent {
  final String amount;
  final String challanId;
  final String violatorName;

  const PaymentBqrEvent({
    required this.amount,
    required this.challanId,
    required this.violatorName,
  });

  @override
  String toString() =>
      'PaymentBqrEvent(amount: $amount, challanId: $challanId)';
}

/// Event to process QR payment
class PaymentQrEvent extends PaymentEvent {
  final String amount;
  final String challanId;
  final String violatorName;

  const PaymentQrEvent({
    required this.amount,
    required this.challanId,
    required this.violatorName,
  });

  @override
  String toString() => 'PaymentQrEvent(amount: $amount, challanId: $challanId)';
}

/// Event to process Cash at POS payment
class PaymentCashAtPosEvent extends PaymentEvent {
  final String amount;
  final String challanId;
  final String violatorName;

  const PaymentCashAtPosEvent({
    required this.amount,
    required this.challanId,
    required this.violatorName,
  });

  @override
  String toString() =>
      'PaymentCashAtPosEvent(amount: $amount, challanId: $challanId)';
}

/// Event to process Pre-Auth payment
class PaymentPreAuthEvent extends PaymentEvent {
  final String amount;
  final String challanId;
  final String violatorName;

  const PaymentPreAuthEvent({
    required this.amount,
    required this.challanId,
    required this.violatorName,
  });

  @override
  String toString() =>
      'PaymentPreAuthEvent(amount: $amount, challanId: $challanId)';
}

/// Event to process Auth Completion
class PaymentAuthCompletionEvent extends PaymentEvent {
  final String amount;
  final String challanId;
  final String violatorName;

  const PaymentAuthCompletionEvent({
    required this.amount,
    required this.challanId,
    required this.violatorName,
  });

  @override
  String toString() =>
      'PaymentAuthCompletionEvent(amount: $amount, challanId: $challanId)';
}

/// Event to process Settlement
class PaymentSettlementEvent extends PaymentEvent {
  const PaymentSettlementEvent();

  @override
  String toString() => 'PaymentSettlementEvent()';
}

/// Event to get Last Receipt
class PaymentLastReceiptEvent extends PaymentEvent {
  const PaymentLastReceiptEvent();

  @override
  String toString() => 'PaymentLastReceiptEvent()';
}

/// Event to get Any Receipt
class PaymentAnyReceiptEvent extends PaymentEvent {
  final String invoiceNumber;

  const PaymentAnyReceiptEvent({required this.invoiceNumber});

  @override
  String toString() => 'PaymentAnyReceiptEvent(invoiceNumber: $invoiceNumber)';
}

/// Event to get Detail Report
class PaymentDetailReportEvent extends PaymentEvent {
  const PaymentDetailReportEvent();

  @override
  String toString() => 'PaymentDetailReportEvent()';
}
