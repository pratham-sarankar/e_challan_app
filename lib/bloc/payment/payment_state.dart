import '../../models/payment_models.dart';

/// Payment BLoC States
/// Defines all possible states in the payment flow
/// Following BLoC pattern for predictable state management

/// Base class for all payment states
abstract class PaymentState {
  const PaymentState();
}

/// Initial state when payment flow starts
class PaymentInitialState extends PaymentState {
  const PaymentInitialState();
}

/// State when payment is being initialized
class PaymentInitializingState extends PaymentState {
  final String challanId;
  final String amount;

  const PaymentInitializingState({
    required this.challanId,
    required this.amount,
  });

  @override
  String toString() =>
      'PaymentInitializingState(challanId: $challanId, amount: $amount)';
}

/// State when payment is ready for processing
class PaymentReadyState extends PaymentState {
  final String challanId;
  final String amount;
  final String violatorName;
  final String violatorMobile;
  final PaymentConfig config;
  final List<String> availablePaymentMethods;

  const PaymentReadyState({
    required this.challanId,
    required this.amount,
    required this.violatorName,
    required this.violatorMobile,
    required this.config,
    required this.availablePaymentMethods,
  });

  @override
  String toString() =>
      'PaymentReadyState(challanId: $challanId, amount: $amount)';
}

/// State when POS payment is being processed
class PaymentPosProcessingState extends PaymentState {
  final PosRequest request;

  const PaymentPosProcessingState({required this.request});

  @override
  String toString() =>
      'PaymentPosProcessingState(billNumber: ${request.billNumber})';
}

/// State when UPI payment is being processed
class PaymentUpiProcessingState extends PaymentState {
  final String amount;
  final String challanId;
  final String qrCodeData;

  const PaymentUpiProcessingState({
    required this.amount,
    required this.challanId,
    required this.qrCodeData,
  });

  @override
  String toString() =>
      'PaymentUpiProcessingState(amount: $amount, challanId: $challanId)';
}

/// State when cash payment is being processed
class PaymentCashProcessingState extends PaymentState {
  final String amount;
  final String challanId;
  final String violatorName;

  const PaymentCashProcessingState({
    required this.amount,
    required this.challanId,
    required this.violatorName,
  });

  @override
  String toString() =>
      'PaymentCashProcessingState(amount: $amount, challanId: $challanId)';
}

/// State when payment is completed successfully
class PaymentSuccessState extends PaymentState {
  final PaymentTransaction transaction;
  final PosResponse? posResponse;
  final String receiptNumber;

  const PaymentSuccessState({
    required this.transaction,
    this.posResponse,
    required this.receiptNumber,
  });

  @override
  String toString() =>
      'PaymentSuccessState(transactionId: ${transaction.transactionId})';
}

/// State when payment fails
class PaymentFailureState extends PaymentState {
  final String error;
  final String? errorCode;
  final PaymentTransaction? partialTransaction;

  const PaymentFailureState({
    required this.error,
    this.errorCode,
    this.partialTransaction,
  });

  @override
  String toString() =>
      'PaymentFailureState(error: $error, errorCode: $errorCode)';
}

/// State when payment is being voided
class PaymentVoidingState extends PaymentState {
  final String billNumber;

  const PaymentVoidingState({required this.billNumber});

  @override
  String toString() => 'PaymentVoidingState(billNumber: $billNumber)';
}

/// State when payment void is successful
class PaymentVoidSuccessState extends PaymentState {
  final String billNumber;
  final PosResponse voidResponse;

  const PaymentVoidSuccessState({
    required this.billNumber,
    required this.voidResponse,
  });

  @override
  String toString() => 'PaymentVoidSuccessState(billNumber: $billNumber)';
}

/// State when payment void fails
class PaymentVoidFailureState extends PaymentState {
  final String billNumber;
  final String error;

  const PaymentVoidFailureState({
    required this.billNumber,
    required this.error,
  });

  @override
  String toString() =>
      'PaymentVoidFailureState(billNumber: $billNumber, error: $error)';
}

/// State when checking payment status
class PaymentStatusCheckingState extends PaymentState {
  final String transactionId;

  const PaymentStatusCheckingState({required this.transactionId});

  @override
  String toString() =>
      'PaymentStatusCheckingState(transactionId: $transactionId)';
}

/// State when payment status is retrieved
class PaymentStatusRetrievedState extends PaymentState {
  final String transactionId;
  final PosResponse statusResponse;

  const PaymentStatusRetrievedState({
    required this.transactionId,
    required this.statusResponse,
  });

  @override
  String toString() =>
      'PaymentStatusRetrievedState(transactionId: $transactionId)';
}

/// State when generating receipt
class PaymentReceiptGeneratingState extends PaymentState {
  final PaymentTransaction transaction;

  const PaymentReceiptGeneratingState({required this.transaction});

  @override
  String toString() =>
      'PaymentReceiptGeneratingState(transactionId: ${transaction.transactionId})';
}

/// State when receipt is generated
class PaymentReceiptGeneratedState extends PaymentState {
  final PaymentTransaction transaction;
  final String receiptPath;

  const PaymentReceiptGeneratedState({
    required this.transaction,
    required this.receiptPath,
  });

  @override
  String toString() =>
      'PaymentReceiptGeneratedState(transactionId: ${transaction.transactionId})';
}

/// State when POS app is not installed
class PaymentPosNotInstalledState extends PaymentState {
  final String message;

  const PaymentPosNotInstalledState({required this.message});

  @override
  String toString() => 'PaymentPosNotInstalledState(message: $message)';
}

/// State when there's a configuration error
class PaymentConfigErrorState extends PaymentState {
  final String error;

  const PaymentConfigErrorState({required this.error});

  @override
  String toString() => 'PaymentConfigErrorState(error: $error)';
}
