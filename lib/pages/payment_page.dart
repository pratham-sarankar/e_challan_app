import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import 'package:municipal_e_challan/bloc/payment/payment_bloc.dart';
import 'package:municipal_e_challan/bloc/payment/payment_event.dart';
import 'package:municipal_e_challan/bloc/payment/payment_state.dart';
import 'package:municipal_e_challan/models/payment_models.dart';
import 'package:municipal_e_challan/services/payment_service.dart';

import 'dashboard_page.dart';

/// Payment Page with BLoC integration for ICICI POS payments
/// Provides multiple payment options: Card (POS), UPI, and Cash
class PaymentPage extends StatelessWidget {
  final int index;

  const PaymentPage({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final challan = DashboardPage.challans[index];
    final amount = challan['amount'] ?? '0';
    final challanId = 'CHALLAN_${index + 1}';
    final violatorName = challan['name'] ?? '';
    final violatorMobile = challan['mobile'] ?? '';

    // Create PaymentBloc with dependency injection
    return BlocProvider(
      create: (context) =>
          PaymentBloc(
            paymentService: PaymentServiceFactory.create(useMock: false),
            config: PaymentConfig.defaultConfig,
          )..add(
            PaymentInitializeEvent(
              challanId: challanId,
              amount: amount,
              violatorName: violatorName,
              violatorMobile: violatorMobile,
            ),
          ),
      child: PaymentPageView(
        index: index,
        challan: challan,
        amount: amount,
        challanId: challanId,
        violatorName: violatorName,
        violatorMobile: violatorMobile,
      ),
    );
  }
}

/// Payment Page View Widget - handles UI rendering
class PaymentPageView extends StatelessWidget {
  final int index;
  final Map<String, dynamic> challan;
  final String amount;
  final String challanId;
  final String violatorName;
  final String violatorMobile;

  const PaymentPageView({
    super.key,
    required this.index,
    required this.challan,
    required this.amount,
    required this.challanId,
    required this.violatorName,
    required this.violatorMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Options"), elevation: 0),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          _handleStateChanges(context, state);
        },
        builder: (context, state) {
          return _buildPaymentUI(context, state);
        },
      ),
    );
  }

  /// Build the payment UI based on current state
  Widget _buildPaymentUI(BuildContext context, PaymentState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challan Information Card
          _buildChallanInfoCard(context),
          const SizedBox(height: 24),

          // Payment Amount Card
          _buildPaymentAmountCard(),
          const SizedBox(height: 24),

          // Payment Options based on state
          _buildPaymentOptions(context, state),

          // Help Information
          _buildHelpInfo(),
        ],
      ),
    );
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
            _buildInfoRow("Challan ID", challanId),
            _buildInfoRow("Violator Name", violatorName),
            _buildInfoRow("Mobile", violatorMobile),
            _buildInfoRow("Rule Violated", challan['rule'] ?? ''),
          ],
        ),
      ),
    );
  }

  /// Build payment amount card
  Widget _buildPaymentAmountCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              "Payable Amount",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              "₹$amount",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build payment options based on current state
  Widget _buildPaymentOptions(BuildContext context, PaymentState state) {
    if (state is PaymentPosNotInstalledState) {
      return _buildPosNotInstalledCard(state.message, context);
    }

    if (state is PaymentReadyState) {
      return _buildPaymentMethodsCard(context, state);
    }

    if (state is PaymentPosProcessingState) {
      return _buildProcessingCard("Processing Card Payment...");
    }

    if (state is PaymentUpiProcessingState) {
      return _buildUpiPaymentCard(context, state);
    }

    if (state is PaymentCashProcessingState) {
      return _buildCashProcessingCard();
    }

    if (state is PaymentSuccessState) {
      return _buildSuccessCard(context, state);
    }

    if (state is PaymentFailureState) {
      return _buildFailureCard(state.error, context);
    }

    return _buildLoadingCard();
  }

  /// Build payment methods selection card
  Widget _buildPaymentMethodsCard(
    BuildContext context,
    PaymentReadyState state,
  ) {
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
            if (state.availablePaymentMethods.contains('CARD'))
              _buildPaymentMethodButton(
                context: context,
                icon: Icons.credit_card,
                title: "Card Payment",
                subtitle: "Pay using debit/credit card via ICICI POS",
                color: Colors.blue,
                onTap: () => _processCardPayment(context),
              ),

            if (state.availablePaymentMethods.contains('CARD'))
              const SizedBox(height: 12),
            // QR Payment Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.qr_code,
              title: "UPI Payment",
              subtitle: "Pay using QR code scanning",
              color: Colors.teal,
              onTap: () => _processQrPayment(context),
            ),

            const SizedBox(height: 12),

            /*           // UPI Payment Option
            if (state.availablePaymentMethods.contains('UPI'))
              _buildPaymentMethodButton(
                context: context,
                icon: Icons.qr_code,
                title: "UPI Payment",
                subtitle: "Pay using UPI apps like PhonePe, Google Pay",
                color: Colors.purple,
                onTap: () => _processUpiPayment(context),
              ),
            
            if (state.availablePaymentMethods.contains('UPI'))
              const SizedBox(height: 12),
            */
            // Cash Payment Option
            if (state.availablePaymentMethods.contains('CASH'))
              _buildPaymentMethodButton(
                context: context,
                icon: Icons.money,
                title: "Cash Payment",
                subtitle: "Pay in cash and receive receipt",
                color: Colors.green,
                onTap: () => _processCashPayment(context),
              ),

            if (state.availablePaymentMethods.contains('CASH'))
              const SizedBox(height: 12),

            /*    // BQR Payment Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.qr_code_scanner,
              title: "BQR Payment",
              subtitle: "Pay using Bharat QR code",
              color: Colors.orange,
              onTap: () => _processBqrPayment(context),
            ),
            
            const SizedBox(height: 12),*/

            /*          // Cash at POS Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.point_of_sale,
              title: "Cash at POS",
              subtitle: "Pay cash at POS terminal",
              color: Colors.brown,
              onTap: () => _processCashAtPosPayment(context),
            ),*/

            /*  const SizedBox(height: 12),
            
            // Pre-Auth Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.lock_clock,
              title: "Pre-Auth Payment",
              subtitle: "Authorize payment before completion",
              color: Colors.purple,
              onTap: () => _processPreAuthPayment(context),
            ),*/
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
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
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

  /// Build UPI payment card with QR code
  Widget _buildUpiPaymentCard(
    BuildContext context,
    PaymentUpiProcessingState state,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "UPI Payment",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Scan QR code using any UPI app",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: BarcodeWidget(
                barcode: Barcode.qrCode(
                  errorCorrectLevel: BarcodeQRCorrectionLevel.high,
                ),
                data: state.qrCodeData,
                width: 200,
                height: 200,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Municipal Corporation",
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<PaymentBloc>().add(
                      const PaymentResetEvent(),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _simulateUpiSuccess(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Payment Done"),
                  ),
                ),
              ],
            ),
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
  Widget _buildSuccessCard(BuildContext context, PaymentSuccessState state) {
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
            const SizedBox(height: 8),
            Text(
              "Receipt Number: ${state.receiptNumber}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _showReceiptDialog(context, challan, state.transaction),
                icon: const Icon(Icons.receipt),
                label: const Text("View Receipt"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
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
                onPressed: () =>
                    context.read<PaymentBloc>().add(const PaymentResetEvent()),
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
                onPressed: () =>
                    context.read<PaymentBloc>().add(const PaymentResetEvent()),
                child: const Text("Continue with Other Options"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading card
  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  /// Build cash processing card
  Widget _buildCashProcessingCard() {
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
              "Processing Cash Payment...",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
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

  /// Handle state changes
  void _handleStateChanges(BuildContext context, PaymentState state) {
    if (state is PaymentSuccessState) {
      // Mark challan as paid
      DashboardPage.challans[index]["status"] = "Paid";

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment successful! Receipt: ${state.receiptNumber}"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else if (state is PaymentFailureState) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed: ${state.error}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Process card payment
  void _processCardPayment(BuildContext context) {
    final billNumber = PaymentService.generateBillNumber(challanId);
    final request = PosRequest(
      amount: amount,
      tranType: 'SALE',
      billNumber: billNumber,
      sourceId: PaymentConfig.defaultConfig.sourceId,
      printFlag: '1',
      udf: {
        'UDF1': challanId,
        'UDF2': violatorName,
        'UDF3': violatorMobile,
        'UDF4': challan['rule'] ?? '',
        'UDF5': 'MUNICIPAL_CHALLAN',
      },
    );

    context.read<PaymentBloc>().add(PaymentProcessEvent(posRequest: request));
  }

  /// Process UPI payment
  void _processUpiPayment(BuildContext context) {
    context.read<PaymentBloc>().add(
      PaymentUpiEvent(
        amount: amount,
        challanId: challanId,
        violatorName: violatorName,
      ),
    );
  }

  /// Process cash payment
  void _processCashPayment(BuildContext context) {
    context.read<PaymentBloc>().add(
      PaymentCashEvent(
        amount: amount,
        challanId: challanId,
        violatorName: violatorName,
      ),
    );
  }

  /// Simulate UPI payment success
  void _simulateUpiSuccess(BuildContext context) {
    // In real implementation, this would be handled by UPI callback
    final transaction = PaymentTransaction(
      transactionId: PaymentService.generateTransactionId(),
      challanId: challanId,
      amount: amount,
      paymentMethod: 'UPI',
      status: 'COMPLETED',
      timestamp: DateTime.now(),
      receiptNumber: 'UPI_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Mark challan as paid
    DashboardPage.challans[index]["status"] = "Paid";

    // Show receipt dialog
    _showReceiptDialog(context, challan, transaction);

    // Navigate back
    Navigator.pop(context);
    Navigator.pop(context);
  }

  /// Process BQR payment
  void _processBqrPayment(BuildContext context) {
    context.read<PaymentBloc>().add(
      PaymentBqrEvent(
        amount: amount,
        challanId: challanId,
        violatorName: violatorName,
      ),
    );
  }

  /// Process QR payment
  void _processQrPayment(BuildContext context) {
    context.read<PaymentBloc>().add(
      PaymentQrEvent(
        amount: amount,
        challanId: challanId,
        violatorName: violatorName,
      ),
    );
  }

  /// Process Cash at POS payment
  void _processCashAtPosPayment(BuildContext context) {
    context.read<PaymentBloc>().add(
      PaymentCashAtPosEvent(
        amount: amount,
        challanId: challanId,
        violatorName: violatorName,
      ),
    );
  }

  /// Process Pre-Auth payment
  void _processPreAuthPayment(BuildContext context) {
    context.read<PaymentBloc>().add(
      PaymentPreAuthEvent(
        amount: amount,
        challanId: challanId,
        violatorName: violatorName,
      ),
    );
  }
}

/// Helper method to build a receipt row (enhanced for better alignment and styling, with overflow prevention)
Widget _buildReceiptRow({
  required String label,
  required String value,
  bool isStatus = false,
  bool isTotal = false,
  IconData? icon,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label with optional icon (now with overflow handling and tighter spacing)
        Expanded(
          flex: 2,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: Colors.grey[600],
                ), // Slightly smaller icon
                SizedBox(width: 6), // Reduced spacing to prevent overflow
              ],
              Flexible(
                // This is fine: Flexible inside Row (Flex)
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  overflow:
                      TextOverflow.ellipsis, // Ellipsis if text is too long
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        // Value with special styling (SIMPLIFIED: No Container/Align/Flexible to avoid ParentData error)
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isStatus
                  ? Colors.green[700]
                  : isTotal
                  ? Colors.black87
                  : Colors.grey[700],
            ),
            textAlign: TextAlign.right, // Align right directly on Text
            overflow:
                TextOverflow.ellipsis, // Ellipsis if needed (rare for values)
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

/// Show receipt dialog (redesigned for modern, clean UI - unchanged from previous)
Future<void> _showReceiptDialog(
  BuildContext context,
  Map<String, dynamic> challan, [
  PaymentTransaction? transaction,
]) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // Prevent accidental dismissal
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16), // Responsive padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Softer corners
      ),
      elevation: 8, // Add subtle shadow
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ), // Limit height for scrollability
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Bar-like Header (modern, with close button)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title with icon
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          "PAYMENT RECEIPT",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Organization Header (below the green bar)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: Colors.grey[50],
              child: const Center(
                child: Text(
                  "Municipal Corporation Bilaspur",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),

            // Scrollable Receipt Content (for better handling on small screens)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt Details Section
                    _buildReceiptRow(
                      label: "Receipt No.",
                      value: "#${DateTime.now().millisecondsSinceEpoch}",
                      icon: Icons.receipt,
                    ),
                    _buildReceiptRow(
                      label: "Date & Time",
                      value: DateFormat(
                        'dd/MM/yyyy hh:mm a',
                      ).format(DateTime.now()),
                      icon: Icons.calendar_today,
                    ),
                    _buildReceiptRow(
                      label: "Name",
                      value: challan['name'] ?? 'N/A',
                      icon: Icons.person,
                    ),
                    _buildReceiptRow(
                      label: "Amount",
                      value: "₹${challan['amount'] ?? 0}",
                      icon: Icons.attach_money,
                    ),
                    _buildReceiptRow(
                      label: "Payment Mode",
                      value: "Cash",
                      icon: Icons.payment,
                    ),
                    _buildReceiptRow(
                      label: "Status",
                      value: "Paid",
                      isStatus: true,
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(height: 24),

                    // Divider for separation
                    Divider(
                      thickness: 1.5,
                      color: Colors.grey[300],
                      height: 32,
                    ),

                    // Additional Details Section
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Additional Details",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    _buildReceiptRow(
                      label: "Rule",
                      value: challan['rule'] ?? 'N/A',
                      icon: Icons.rule,
                    ),
                    _buildReceiptRow(
                      label: "Total Amount",
                      value: "₹${challan['amount'] ?? 0}",
                      isTotal: true,
                      icon: Icons.calculate,
                    ),
                  ],
                ),
              ),
            ),

            // Footer with Actions (modern buttons with consistent styling)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Close Button (outlined for subtlety)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text("CLOSE"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Print Button (filled, prominent)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _printReceipt(challan);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.print, size: 20),
                      label: const Text("PRINT"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _printReceipt(Map<String, dynamic> challan) async {
  // Create PDF document with standard A4 page size
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4, // Standard A4 size (210mm x 297mm)
      build: (pw.Context context) => pw.Center(
        // Center the content for better aesthetics
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(40), // Add padding for margins
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              // Header with title (centered and bold)
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Municipal Corporation Bilaspur',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PAYMENT RECEIPT',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Receipt details in a structured table for better alignment
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                defaultColumnWidth: const pw.FlexColumnWidth(2),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Receipt No.:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '#${DateTime.now().millisecondsSinceEpoch}',
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date & Time:'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          DateFormat(
                            'dd/MM/yyyy hh:mm a',
                          ).format(DateTime.now()),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Name:'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(challan['name'] ?? 'N/A'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount:'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${challan['amount'] ?? 0}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Rule:'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('${challan['rule'] ?? 0}'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Payment Mode:'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Cash'),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.green100),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Status:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Paid',
                          style: pw.TextStyle(
                            color: PdfColors.green800,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 40),

              // Footer (optional: add any additional notes or signature line)
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              pw.Container(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'Thank you for your payment!',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                child: pw.Row(
                  children: [
                    pw.Expanded(child: pw.Container()),
                    pw.Text('Signature: ________________'),
                    pw.Expanded(child: pw.Container()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Layout and print the PDF (standard printing flow)
  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}
