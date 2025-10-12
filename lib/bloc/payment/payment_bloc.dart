/// Payment BLoC - Business Logic Component for payment management
/// Handles all payment-related business logic and state management
/// Following clean architecture principles with dependency injection
library;

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/payment_models.dart';
import '../../services/payment_service.dart';
import 'payment_event.dart';
import 'payment_state.dart';

/// Payment BLoC class that manages payment state and business logic
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final IPaymentService _paymentService;
  final PaymentConfig _config;

  /// Constructor with dependency injection
  PaymentBloc({required IPaymentService paymentService, PaymentConfig? config})
    : _paymentService = paymentService,
      _config = config ?? PaymentConfig.defaultConfig,
      super(const PaymentInitialState()) {
    // Register event handlers
    on<PaymentInitializeEvent>(_onInitialize);
    on<PaymentProcessEvent>(_onProcessPayment);
    on<PaymentUpiEvent>(_onUpiPayment);
    on<PaymentCashEvent>(_onCashPayment);
    on<PaymentVoidEvent>(_onVoidPayment);
    on<PaymentStatusCheckEvent>(_onCheckStatus);
    on<PaymentReceiptEvent>(_onGenerateReceipt);
    on<PaymentResetEvent>(_onReset);
    on<PaymentConfigUpdateEvent>(_onUpdateConfig);
    on<PaymentErrorEvent>(_onError);

    // Additional transaction mode handlers
    on<PaymentBqrEvent>(_onBqrPayment);
    on<PaymentQrEvent>(_onQrPayment);
    on<PaymentCashAtPosEvent>(_onCashAtPosPayment);
    on<PaymentPreAuthEvent>(_onPreAuthPayment);
    on<PaymentAuthCompletionEvent>(_onAuthCompletion);
    on<PaymentSettlementEvent>(_onSettlement);
    on<PaymentLastReceiptEvent>(_onLastReceipt);
    on<PaymentAnyReceiptEvent>(_onAnyReceipt);
    on<PaymentDetailReportEvent>(_onDetailReport);
  }

  /// Initialize payment for a challan
  Future<void> _onInitialize(
    PaymentInitializeEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(
        PaymentInitializingState(
          challanId: event.challanId,
          amount: event.amount,
        ),
      );

      // Check if POS app is installed
      final isPosInstalled = await _paymentService.isPosAppInstalled();
      if (!isPosInstalled) {
        emit(
          PaymentPosNotInstalledState(
            message:
                'ICICI POS app is not installed. Please install it to process card payments.',
          ),
        );
        return;
      }

      // Determine available payment methods
      final availableMethods = _config.supportedPaymentMethods;

      emit(
        PaymentReadyState(
          challanId: event.challanId,
          amount: event.amount,
          violatorName: event.violatorName,
          violatorMobile: event.violatorMobile,
          config: _config,
          availablePaymentMethods: availableMethods,
        ),
      );
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Failed to initialize payment: $e',
          errorCode: 'INIT_ERROR',
        ),
      );
    }
  }

  /// Process POS payment
  Future<void> _onProcessPayment(
    PaymentProcessEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentPosProcessingState(request: event.posRequest));

      final response = await _paymentService.processPayment(event.posRequest);

      if (response.isSuccess) {
        // Create payment transaction
        final transaction = PaymentTransaction(
          transactionId: PaymentService.generateTransactionId(),
          challanId: _extractChallanIdFromBillNumber(
            event.posRequest.billNumber,
          ),
          amount: event.posRequest.amount,
          paymentMethod: 'CARD',
          status: 'COMPLETED',
          timestamp: DateTime.now(),
          posResponse: response,
          receiptNumber: response.receiptData?['InvoiceNr']?.toString(),
        );

        emit(
          PaymentSuccessState(
            transaction: transaction,
            posResponse: response,
            receiptNumber: transaction.receiptNumber ?? '',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Payment processing failed: $e',
          errorCode: 'PROCESS_ERROR',
        ),
      );
    }
  }

  /// Process UPI payment
  Future<void> _onUpiPayment(
    PaymentUpiEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      // Generate UPI payment data
      final qrData =
          "UPI://pay?pa=municipalcorp@upi&am=${event.amount}&tn=ChallanPayment_${event.challanId}";

      emit(
        PaymentUpiProcessingState(
          amount: event.amount,
          challanId: event.challanId,
          qrCodeData: qrData,
        ),
      );

      // In a real implementation, you would wait for UPI callback
      // For now, we'll simulate a successful UPI payment after a delay
      await Future.delayed(const Duration(seconds: 3));

      final transaction = PaymentTransaction(
        transactionId: PaymentService.generateTransactionId(),
        challanId: event.challanId,
        amount: event.amount,
        paymentMethod: 'UPI',
        status: 'COMPLETED',
        timestamp: DateTime.now(),
        receiptNumber: 'UPI_${DateTime.now().millisecondsSinceEpoch}',
      );

      emit(
        PaymentSuccessState(
          transaction: transaction,
          receiptNumber: transaction.receiptNumber!,
        ),
      );
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'UPI payment failed: $e',
          errorCode: 'UPI_ERROR',
        ),
      );
    }
  }

  /// Process cash payment
  Future<void> _onCashPayment(
    PaymentCashEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(
        PaymentCashProcessingState(
          amount: event.amount,
          challanId: event.challanId,
          violatorName: event.violatorName,
        ),
      );

      // Simulate cash payment processing
      await Future.delayed(const Duration(seconds: 1));

      final transaction = PaymentTransaction(
        transactionId: PaymentService.generateTransactionId(),
        challanId: event.challanId,
        amount: event.amount,
        paymentMethod: 'CASH',
        status: 'COMPLETED',
        timestamp: DateTime.now(),
        receiptNumber: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
      );

      emit(
        PaymentSuccessState(
          transaction: transaction,
          receiptNumber: transaction.receiptNumber!,
        ),
      );
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Cash payment failed: $e',
          errorCode: 'CASH_ERROR',
        ),
      );
    }
  }

  /// Void payment transaction
  Future<void> _onVoidPayment(
    PaymentVoidEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentVoidingState(billNumber: event.billNumber));

      final response = await _paymentService.voidPayment(event.billNumber);

      if (response.isSuccess) {
        emit(
          PaymentVoidSuccessState(
            billNumber: event.billNumber,
            voidResponse: response,
          ),
        );
      } else {
        emit(
          PaymentVoidFailureState(
            billNumber: event.billNumber,
            error: response.statusMessage,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentVoidFailureState(
          billNumber: event.billNumber,
          error: 'Void payment failed: $e',
        ),
      );
    }
  }

  /// Check payment status
  Future<void> _onCheckStatus(
    PaymentStatusCheckEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentStatusCheckingState(transactionId: event.transactionId));

      final response = await _paymentService.checkTransactionStatus(
        event.transactionId,
      );

      emit(
        PaymentStatusRetrievedState(
          transactionId: event.transactionId,
          statusResponse: response,
        ),
      );
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Status check failed: $e',
          errorCode: 'STATUS_ERROR',
        ),
      );
    }
  }

  /// Generate payment receipt
  Future<void> _onGenerateReceipt(
    PaymentReceiptEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(PaymentReceiptGeneratingState(transaction: event.transaction));

      // Simulate receipt generation
      await Future.delayed(const Duration(seconds: 1));

      final receiptPath = '/receipts/${event.transaction.transactionId}.pdf';

      emit(
        PaymentReceiptGeneratedState(
          transaction: event.transaction,
          receiptPath: receiptPath,
        ),
      );
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Receipt generation failed: $e',
          errorCode: 'RECEIPT_ERROR',
        ),
      );
    }
  }

  /// Reset payment state
  void _onReset(PaymentResetEvent event, Emitter<PaymentState> emit) {
    emit(const PaymentInitialState());
  }

  /// Update payment configuration
  void _onUpdateConfig(
    PaymentConfigUpdateEvent event,
    Emitter<PaymentState> emit,
  ) {
    // Update configuration and reinitialize if needed
    // This would require recreating the bloc with new config
    emit(
      PaymentConfigErrorState(
        error: 'Configuration update requires bloc recreation',
      ),
    );
  }

  /// Handle payment errors
  void _onError(PaymentErrorEvent event, Emitter<PaymentState> emit) {
    emit(PaymentFailureState(error: event.error, errorCode: event.code));
  }

  /// Helper method to extract challan ID from bill number
  String _extractChallanIdFromBillNumber(String billNumber) {
    // Extract challan ID from bill number format: CHALLAN_{challanId}_{timestamp}
    final parts = billNumber.split('_');
    if (parts.length >= 3) {
      return parts[1];
    }
    return billNumber;
  }

  /// Process BQR payment
  Future<void> _onBqrPayment(
    PaymentBqrEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final billNumber = PaymentService.generateBillNumber(event.challanId);
      emit(
        PaymentPosProcessingState(
          request: PosRequest(
            amount: event.amount,
            tranType: 'BQR',
            billNumber: billNumber,
            sourceId: _config.sourceId,
          ),
        ),
      );

      final response = await (_paymentService as PaymentService)
          .processBqrPayment(event.amount, billNumber);

      if (response.isSuccess) {
        final transaction = PaymentTransaction(
          transactionId: PaymentService.generateTransactionId(),
          challanId: event.challanId,
          amount: event.amount,
          paymentMethod: 'BQR',
          status: 'COMPLETED',
          timestamp: DateTime.now(),
          posResponse: response,
          receiptNumber: response.receiptData?['InvoiceNr']?.toString(),
        );

        emit(
          PaymentSuccessState(
            transaction: transaction,
            posResponse: response,
            receiptNumber: transaction.receiptNumber ?? '',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'BQR payment failed: $e',
          errorCode: 'BQR_ERROR',
        ),
      );
    }
  }

  /// Process QR payment
  Future<void> _onQrPayment(
    PaymentQrEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final billNumber = PaymentService.generateBillNumber(event.challanId);
      emit(
        PaymentPosProcessingState(
          request: PosRequest(
            amount: event.amount,
            tranType: 'QR',
            billNumber: billNumber,
            sourceId: _config.sourceId,
          ),
        ),
      );

      final response = await (_paymentService as PaymentService)
          .processQrPayment(event.amount, billNumber);

      if (response.isSuccess) {
        final transaction = PaymentTransaction(
          transactionId: PaymentService.generateTransactionId(),
          challanId: event.challanId,
          amount: event.amount,
          paymentMethod: 'QR',
          status: 'COMPLETED',
          timestamp: DateTime.now(),
          posResponse: response,
          receiptNumber: response.receiptData?['InvoiceNr']?.toString(),
        );

        emit(
          PaymentSuccessState(
            transaction: transaction,
            posResponse: response,
            receiptNumber: transaction.receiptNumber ?? '',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'QR payment failed: $e',
          errorCode: 'QR_ERROR',
        ),
      );
    }
  }

  /// Process Cash at POS payment
  Future<void> _onCashAtPosPayment(
    PaymentCashAtPosEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final billNumber = PaymentService.generateBillNumber(event.challanId);
      emit(
        PaymentPosProcessingState(
          request: PosRequest(
            amount: event.amount,
            tranType: 'CASHATPOS',
            billNumber: billNumber,
            sourceId: _config.sourceId,
          ),
        ),
      );

      final response = await (_paymentService as PaymentService)
          .processCashAtPosPayment(event.amount, billNumber);

      if (response.isSuccess) {
        final transaction = PaymentTransaction(
          transactionId: PaymentService.generateTransactionId(),
          challanId: event.challanId,
          amount: event.amount,
          paymentMethod: 'CASH_AT_POS',
          status: 'COMPLETED',
          timestamp: DateTime.now(),
          posResponse: response,
          receiptNumber: response.receiptData?['InvoiceNr']?.toString(),
        );

        emit(
          PaymentSuccessState(
            transaction: transaction,
            posResponse: response,
            receiptNumber: transaction.receiptNumber ?? '',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Cash at POS payment failed: $e',
          errorCode: 'CASH_AT_POS_ERROR',
        ),
      );
    }
  }

  /// Process Pre-Auth payment
  Future<void> _onPreAuthPayment(
    PaymentPreAuthEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final billNumber = PaymentService.generateBillNumber(event.challanId);
      emit(
        PaymentPosProcessingState(
          request: PosRequest(
            amount: event.amount,
            tranType: 'PREAUTH',
            billNumber: billNumber,
            sourceId: _config.sourceId,
          ),
        ),
      );

      final response = await (_paymentService as PaymentService)
          .processPreAuthPayment(event.amount, billNumber);

      if (response.isSuccess) {
        final transaction = PaymentTransaction(
          transactionId: PaymentService.generateTransactionId(),
          challanId: event.challanId,
          amount: event.amount,
          paymentMethod: 'PRE_AUTH',
          status: 'COMPLETED',
          timestamp: DateTime.now(),
          posResponse: response,
          receiptNumber: response.receiptData?['InvoiceNr']?.toString(),
        );

        emit(
          PaymentSuccessState(
            transaction: transaction,
            posResponse: response,
            receiptNumber: transaction.receiptNumber ?? '',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Pre-Auth payment failed: $e',
          errorCode: 'PRE_AUTH_ERROR',
        ),
      );
    }
  }

  /// Process Auth Completion
  Future<void> _onAuthCompletion(
    PaymentAuthCompletionEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      final billNumber = PaymentService.generateBillNumber(event.challanId);
      emit(
        PaymentPosProcessingState(
          request: PosRequest(
            amount: event.amount,
            tranType: 'AUTHCOMPLETION',
            billNumber: billNumber,
            sourceId: _config.sourceId,
          ),
        ),
      );

      final response = await (_paymentService as PaymentService)
          .processAuthCompletion(event.amount, billNumber);

      if (response.isSuccess) {
        final transaction = PaymentTransaction(
          transactionId: PaymentService.generateTransactionId(),
          challanId: event.challanId,
          amount: event.amount,
          paymentMethod: 'AUTH_COMPLETION',
          status: 'COMPLETED',
          timestamp: DateTime.now(),
          posResponse: response,
          receiptNumber: response.receiptData?['InvoiceNr']?.toString(),
        );

        emit(
          PaymentSuccessState(
            transaction: transaction,
            posResponse: response,
            receiptNumber: transaction.receiptNumber ?? '',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Auth Completion failed: $e',
          errorCode: 'AUTH_COMPLETION_ERROR',
        ),
      );
    }
  }

  /// Process Settlement
  Future<void> _onSettlement(
    PaymentSettlementEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(
        PaymentPosProcessingState(
          request: PosRequest(
            amount: '0.00',
            tranType: 'SETTLEMENT',
            billNumber: 'SETTLEMENT',
            sourceId: _config.sourceId,
          ),
        ),
      );

      final response = await (_paymentService as PaymentService)
          .processSettlement();

      if (response.isSuccess) {
        emit(
          PaymentSuccessState(
            transaction: PaymentTransaction(
              transactionId: PaymentService.generateTransactionId(),
              challanId: 'SETTLEMENT',
              amount: '0.00',
              paymentMethod: 'SETTLEMENT',
              status: 'COMPLETED',
              timestamp: DateTime.now(),
              posResponse: response,
              receiptNumber:
                  'SETTLEMENT_${DateTime.now().millisecondsSinceEpoch}',
            ),
            posResponse: response,
            receiptNumber:
                'SETTLEMENT_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Settlement failed: $e',
          errorCode: 'SETTLEMENT_ERROR',
        ),
      );
    }
  }

  /// Get Last Receipt
  Future<void> _onLastReceipt(
    PaymentLastReceiptEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(
        PaymentReceiptGeneratingState(
          transaction: PaymentTransaction(
            transactionId: 'LAST_RECEIPT',
            challanId: 'LAST_RECEIPT',
            amount: '0.00',
            paymentMethod: 'RECEIPT',
            status: 'COMPLETED',
            timestamp: DateTime.now(),
          ),
        ),
      );

      final response = await (_paymentService as PaymentService)
          .getLastReceipt();

      if (response.isSuccess) {
        emit(
          PaymentReceiptGeneratedState(
            transaction: PaymentTransaction(
              transactionId: 'LAST_RECEIPT',
              challanId: 'LAST_RECEIPT',
              amount: '0.00',
              paymentMethod: 'RECEIPT',
              status: 'COMPLETED',
              timestamp: DateTime.now(),
            ),
            receiptPath: '/receipts/last_receipt.pdf',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Get last receipt failed: $e',
          errorCode: 'LAST_RECEIPT_ERROR',
        ),
      );
    }
  }

  /// Get Any Receipt
  Future<void> _onAnyReceipt(
    PaymentAnyReceiptEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(
        PaymentReceiptGeneratingState(
          transaction: PaymentTransaction(
            transactionId: event.invoiceNumber,
            challanId: event.invoiceNumber,
            amount: '0.00',
            paymentMethod: 'RECEIPT',
            status: 'COMPLETED',
            timestamp: DateTime.now(),
          ),
        ),
      );

      final response = await (_paymentService as PaymentService).getAnyReceipt(
        event.invoiceNumber,
      );

      if (response.isSuccess) {
        emit(
          PaymentReceiptGeneratedState(
            transaction: PaymentTransaction(
              transactionId: event.invoiceNumber,
              challanId: event.invoiceNumber,
              amount: '0.00',
              paymentMethod: 'RECEIPT',
              status: 'COMPLETED',
              timestamp: DateTime.now(),
            ),
            receiptPath: '/receipts/${event.invoiceNumber}.pdf',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Get any receipt failed: $e',
          errorCode: 'ANY_RECEIPT_ERROR',
        ),
      );
    }
  }

  /// Get Detail Report
  Future<void> _onDetailReport(
    PaymentDetailReportEvent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(
        PaymentPosProcessingState(
          request: PosRequest(
            amount: '0.00',
            tranType: 'DETAILREPORT',
            billNumber: 'DETAIL_REPORT',
            sourceId: _config.sourceId,
          ),
        ),
      );

      final response = await (_paymentService as PaymentService)
          .getDetailReport();

      if (response.isSuccess) {
        emit(
          PaymentSuccessState(
            transaction: PaymentTransaction(
              transactionId: PaymentService.generateTransactionId(),
              challanId: 'DETAIL_REPORT',
              amount: '0.00',
              paymentMethod: 'DETAIL_REPORT',
              status: 'COMPLETED',
              timestamp: DateTime.now(),
              posResponse: response,
              receiptNumber:
                  'DETAIL_REPORT_${DateTime.now().millisecondsSinceEpoch}',
            ),
            posResponse: response,
            receiptNumber:
                'DETAIL_REPORT_${DateTime.now().millisecondsSinceEpoch}',
          ),
        );
      } else {
        emit(
          PaymentFailureState(
            error: response.statusMessage,
            errorCode: response.statusCode,
          ),
        );
      }
    } catch (e) {
      emit(
        PaymentFailureState(
          error: 'Detail report failed: $e',
          errorCode: 'DETAIL_REPORT_ERROR',
        ),
      );
    }
  }

  /// Dispose resources
  @override
  Future<void> close() {
    // Clean up any resources if needed
    return super.close();
  }
}
