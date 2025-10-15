import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:municipal_e_challan/models/challan_response.dart';
import 'package:municipal_e_challan/models/payment_models.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:vizpay_flutter/vizpay_flutter.dart';

/// Payment Page View Widget - handles UI rendering
class PaymentPage extends StatefulWidget {
  final ChallanResponse challan;

  const PaymentPage({super.key, required this.challan});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessing = false;
  String _processingMessage = '';
  PaymentTransaction? _transaction;
  String? _errorMessage;
  bool _posNotInstalled = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(title: const Text("Payment Options"), elevation: 0),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChallanInfoCard(context),
              const SizedBox(height: 24),
              _buildPaymentAmountCard(),
              const SizedBox(height: 24),
              _buildPaymentOptions(context),
              const SizedBox(height: 12),
              _buildHelpInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the payment UI based on current state
  Widget _buildPaymentOptions(BuildContext context) {
    if (_posNotInstalled) {
      return _buildPosNotInstalledCard(
        'ICICI POS integration is not available on this device. Please install/configure the POS plugin or use other payment options.',
        context,
      );
    }

    if (_isProcessing) {
      return _buildProcessingCard(
        _processingMessage.isNotEmpty ? _processingMessage : 'Processing...',
      );
    }

    if (_transaction != null) {
      return _buildSuccessCard(context, _transaction!);
    }

    if (_errorMessage != null) {
      return _buildFailureCard(_errorMessage!, context);
    }

    // Default: show available payment methods
    return _buildPaymentMethodsCard(context);
  }

  /// Build challan information card
  Widget _buildChallanInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  "Challan Information",
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Challan ID", widget.challan.challanId.toString()),
            _buildInfoRow("Violator Name", widget.challan.fullName),
            _buildInfoRow("Mobile", widget.challan.contactNumber),
            // TODO: After creating global challan types provider, update this with the rule name instead of the ID.
            _buildInfoRow(
              "Rule Violated",
              widget.challan.challanTypeId.toString(),
            ),
          ],
        ),
      ),
    );
  }

  /// Build payment amount card
  Widget _buildPaymentAmountCard() {
    final amount = widget.challan.fineAmount;
    final formattedAmount = NumberFormat('#,##,###').format(amount);

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.indigo.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Colors.indigo,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Amount to Pay",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "₹$formattedAmount",
                style: const TextStyle(
                  fontSize: 42,
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Inclusive of all charges",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build payment methods selection card
  Widget _buildPaymentMethodsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Payment Method",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Card Payment Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.credit_card,
              title: "Card Payment",
              subtitle: "Pay using debit/credit card via ICICI POS",
              color: Colors.blue,
              onTap: () => _startCardPayment(context),
            ),

            const SizedBox(height: 12),
            // QR Payment Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.qr_code,
              title: "UPI Payment",
              subtitle: "Pay using QR code scanning",
              color: Colors.teal,
              onTap: () => _startUpiPayment(context),
            ),

            const SizedBox(height: 12),

            // Cash Payment Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.money,
              title: "Cash Payment",
              subtitle: "Pay in cash and receive receipt",
              color: Colors.green,
              onTap: () => _processCashPayment(context),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Build individual payment method button
  Widget _buildPaymentMethodButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha((0.3 * 255).round())),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  /// Build processing card
  Widget _buildProcessingCard(String message) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build success card
  Widget _buildSuccessCard(
    BuildContext context,
    PaymentTransaction transaction,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              "Payment Successful!",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8, width: double.infinity),
            Text(
              "Receipt Number: ${transaction.receiptNumber}",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  /// Build failure card
  Widget _buildFailureCard(String error, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              "Payment Failed",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _transaction = null;
                    _isProcessing = false;
                  });
                },
                child: const Text("Try Again"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build POS not installed card
  Widget _buildPosNotInstalledCard(String message, BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text(
              "POS App Not Available",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _posNotInstalled = false;
                  });
                },
                child: const Text("Continue with Other Options"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build help information
  Widget _buildHelpInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.indigo, size: 24),
          const SizedBox(height: 8),
          Text(
            "Choose your preferred payment method. All payments are secure and processed through ICICI Bank.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  /// Build info row for challan details
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Start card payment using PaymentService directly
  Future<void> _startCardPayment(BuildContext context) async {
    try {
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Initiating card payment...';
        _errorMessage = null;
      });

      // Parse amount to ensure proper format
      final double amountValue = widget.challan.fineAmount;
      final String formattedAmount = amountValue.toStringAsFixed(2);

      // Use transaction ID as bill number and challan ID as source ID as requested
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      final billNumber = transactionId; // Transaction ID as bill number
      final sourceId = widget.challan.challanId
          .toString(); // Challan ID as source ID

      setState(() {
        _processingMessage = 'Processing card payment...';
      });

      // Start VizPay sale transaction
      final response = await VizpayFlutter.startSaleTransaction(
        amount: formattedAmount,
        billNumber: billNumber,
        sourceId: sourceId,
        tipAmount: "0.00",
        printFlag: true,
      );

      if (response != null) {
        final statusCode = response["STATUS_CODE"] as String?;
        final statusMsg = response["STATUS_MSG"] as String?;
        final receiptData = response["RECEIPT_DATA"] as String?;

        if (statusCode == "00") {
          // Payment successful - create transaction record
          setState(() {
            _processingMessage =
                'Payment successful! Creating transaction record...';
          });

          try {
            final transactionData = await _apiService.createTransaction(
              challanId: widget.challan.challanId,
              orderStatus: 'paid',
              orderId: transactionId,
              paymentMethod: 'CARD',
              paymentReference: receiptData,
              amount: amountValue,
              notes: 'Card payment via ICICI POS - VizPay',
            );

            // Create successful payment transaction
            final transaction = PaymentTransaction(
              transactionId: transactionId,
              challanId: widget.challan.challanId.toString(),
              amount: formattedAmount,
              paymentMethod: 'CARD',
              status: 'SUCCESS',
              timestamp: DateTime.now(),
              posResponse: PosResponse(
                statusCode: statusCode ?? '00',
                statusMessage: statusMsg ?? 'Approved',
                receiptData: receiptData != null
                    ? {'receipt': receiptData}
                    : null,
                rawResponse: response,
              ),
              receiptNumber: transactionData['id']?.toString(),
            );

            setState(() {
              _isProcessing = false;
              _transaction = transaction;
              _processingMessage = '';
            });

            // Show success message
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Payment Successful'),
                    content: Text(
                      'Payment of ₹$formattedAmount was successful.\nReceipt Number: ${transaction.receiptNumber}',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () {
                          // Navigate to home/dashboard page
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          } catch (e) {
            // Payment was successful but transaction creation failed
            print('Transaction creation failed: $e');
            setState(() {
              _isProcessing = false;
              _errorMessage =
                  'Payment successful but failed to record transaction: ${e.toString()}';
            });
          }
        } else {
          // Payment failed
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Payment failed: ${statusMsg ?? 'Unknown error'}';
          });

          // Try to create a failed transaction record
          try {
            await _apiService.createTransaction(
              challanId: widget.challan.challanId,
              orderStatus: 'failed',
              orderId: transactionId,
              paymentMethod: 'CARD',
              paymentReference: receiptData,
              amount: amountValue,
              notes:
                  'Failed card payment via ICICI POS - VizPay: ${statusMsg ?? 'Unknown error'}',
            );
          } catch (e) {
            print('Failed to record failed transaction: $e');
          }
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'No response from payment app. Please ensure ICICI VizPay app is installed.';
        });
      }
    } catch (e) {
      print('Card payment error: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment error: ${e.toString()}';
      });

      // Try to create a failed transaction record
      try {
        final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
        await _apiService.createTransaction(
          challanId: widget.challan.challanId,
          orderStatus: 'failed',
          orderId: transactionId,
          paymentMethod: 'CARD',
          amount: widget.challan.fineAmount,
          notes: 'Failed card payment due to error: ${e.toString()}',
        );
      } catch (transError) {
        print('Failed to record error transaction: $transError');
      }
    }
  }

  /// Start card payment using PaymentService directly
  Future<void> _startUpiPayment(BuildContext context) async {
    try {
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Initiating UPI payment...';
        _errorMessage = null;
      });

      // Parse amount to ensure proper format
      final double amountValue = widget.challan.fineAmount;
      final String formattedAmount = amountValue.toStringAsFixed(2);

      // Use transaction ID as bill number and challan ID as source ID as requested
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
      final billNumber = transactionId; // Transaction ID as bill number
      final sourceId = widget.challan.challanId
          .toString(); // Challan ID as source ID

      setState(() {
        _processingMessage = 'Processing UPI payment...';
      });

      // Start VizPay sale transaction
      final response = await VizpayFlutter.startUpiTransaction(
        amount: formattedAmount,
        billNumber: billNumber,
        sourceId: sourceId,
        tipAmount: "0.00",
        printFlag: true,
      );

      if (response != null) {
        final statusCode = response["STATUS_CODE"] as String?;
        final statusMsg = response["STATUS_MSG"] as String?;
        final receiptData = response["RECEIPT_DATA"] as String?;

        if (statusCode == "00") {
          // Payment successful - create transaction record
          setState(() {
            _processingMessage =
                'Payment successful! Creating transaction record...';
          });

          try {
            final transactionData = await _apiService.createTransaction(
              challanId: widget.challan.challanId,
              orderStatus: 'paid',
              orderId: transactionId,
              paymentMethod: 'UPI',
              paymentReference: receiptData,
              amount: amountValue,
              notes: 'UPI payment via ICICI POS - VizPay',
            );

            // Create successful payment transaction
            final transaction = PaymentTransaction(
              transactionId: transactionId,
              challanId: widget.challan.challanId.toString(),
              amount: formattedAmount,
              paymentMethod: 'UPI',
              status: 'SUCCESS',
              timestamp: DateTime.now(),
              posResponse: PosResponse(
                statusCode: statusCode ?? '00',
                statusMessage: statusMsg ?? 'Approved',
                receiptData: receiptData != null
                    ? {'receipt': receiptData}
                    : null,
                rawResponse: response,
              ),
              receiptNumber: transactionData['id']?.toString(),
            );

            setState(() {
              _isProcessing = false;
              _transaction = transaction;
              _processingMessage = '';
            });

            // Show success message
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Payment Successful'),
                    content: Text(
                      'Payment of ₹$formattedAmount was successful.\nReceipt Number: ${transaction.receiptNumber}',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () {
                          // Navigate to home/dashboard page
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          } catch (e) {
            // Payment was successful but transaction creation failed
            print('Transaction creation failed: $e');
            setState(() {
              _isProcessing = false;
              _errorMessage =
                  'Payment successful but failed to record transaction: ${e.toString()}';
            });
          }
        } else {
          // Payment failed
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Payment failed: ${statusMsg ?? 'Unknown error'}';
          });

          // Try to create a failed transaction record
          try {
            await _apiService.createTransaction(
              challanId: widget.challan.challanId,
              orderStatus: 'failed',
              orderId: transactionId,
              paymentMethod: 'CARD',
              paymentReference: receiptData,
              amount: amountValue,
              notes:
                  'Failed card payment via ICICI POS - VizPay: ${statusMsg ?? 'Unknown error'}',
            );
          } catch (e) {
            print('Failed to record failed transaction: $e');
          }
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'No response from payment app. Please ensure ICICI VizPay app is installed.';
        });
      }
    } catch (e) {
      print('Card payment error: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment error: ${e.toString()}';
      });

      // Try to create a failed transaction record
      try {
        final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
        await _apiService.createTransaction(
          challanId: widget.challan.challanId,
          orderStatus: 'failed',
          orderId: transactionId,
          paymentMethod: 'CARD',
          amount: widget.challan.fineAmount,
          notes: 'Failed card payment due to error: ${e.toString()}',
        );
      } catch (transError) {
        print('Failed to record error transaction: $transError');
      }
    }
  }

  void _processCashPayment(BuildContext context) async {
    try {
      setState(() {
        _isProcessing = true;
        _processingMessage = 'Processing cash payment...';
        _errorMessage = null;
      });

      // Parse amount to ensure proper format
      final double amountValue = widget.challan.fineAmount;
      final String formattedAmount = amountValue.toStringAsFixed(2);

      // Generate transaction ID
      final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';

      setState(() {
        _processingMessage = 'Recording cash payment transaction...';
      });

      // Create transaction record in the API
      try {
        final transactionData = await _apiService.createTransaction(
          challanId: widget.challan.challanId,
          orderStatus: 'paid',
          orderId: transactionId,
          paymentMethod: 'CASH',
          amount: amountValue,
          notes: 'Cash payment received',
        );

        // Create successful payment transaction
        final transaction = PaymentTransaction(
          transactionId: transactionId,
          challanId: widget.challan.challanId.toString(),
          amount: formattedAmount,
          paymentMethod: 'CASH',
          status: 'SUCCESS',
          timestamp: DateTime.now(),
          receiptNumber:
              transactionData['id']?.toString() ??
              'CASH_${DateTime.now().millisecondsSinceEpoch}',
        );

        setState(() {
          _isProcessing = false;
          _transaction = transaction;
          _processingMessage = '';
        });

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: const Text('Payment Successful'),
                content: Text(
                  'Cash payment of ₹$formattedAmount was successful.\nReceipt Number: ${transaction.receiptNumber}',
                ),
                actions: [
                  FilledButton(
                    onPressed: () {
                      // Navigate to home/dashboard page
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        // Transaction creation failed
        print('Cash transaction creation failed: $e');
        setState(() {
          _isProcessing = false;
          _errorMessage =
              'Failed to record cash payment transaction: ${e.toString()}';
        });
      }
    } catch (e) {
      print('Cash payment error: $e');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Cash payment error: ${e.toString()}';
      });

      // Try to create a failed transaction record
      try {
        final transactionId = 'TXN_${DateTime.now().millisecondsSinceEpoch}';
        await _apiService.createTransaction(
          challanId: widget.challan.challanId,
          orderStatus: 'failed',
          orderId: transactionId,
          paymentMethod: 'CASH',
          amount: widget.challan.fineAmount,
          notes: 'Failed cash payment due to error: ${e.toString()}',
        );
      } catch (transError) {
        print('Failed to record error transaction: $transError');
      }
    }
  }

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN_${timestamp}_$random';
  }
}
