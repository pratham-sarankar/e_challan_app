import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:municipal_e_challan/models/payment_models.dart';
import 'package:municipal_e_challan/services/payment_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'dashboard_page.dart';

/// Payment Page with BLoC integration for ICICI POS payments
/// Provides multiple payment options: Card (POS), UPI, and Cash
class PaymentPage extends StatelessWidget {
  // index may be null if a full challan map is provided directly.
  final int? index;

  // Optional challan map - prefer this when provided to avoid indexing into the global list.
  final Map<String, dynamic>? challan;

  const PaymentPage({super.key, this.index, this.challan});

  @override
  Widget build(BuildContext context) {
    // Resolve challan map safely. Prefer provided challan, then try index lookup when valid,
    // otherwise fall back to an empty map to avoid RangeError.
    Map<String, dynamic> resolvedChallan = {};
    int resolvedIndex = index ?? 0;
    if (challan != null) {
      resolvedChallan = Map<String, dynamic>.from(challan!);
      // attempt to find its index in DashboardPage list if possible
      final idx = DashboardPage.challans.indexWhere((c) {
        try {
          return c == resolvedChallan ||
              (c['id'] != null && c['id'] == resolvedChallan['id']);
        } catch (_) {
          return false;
        }
      });
      if (idx != -1) resolvedIndex = idx;
    } else if (index != null &&
        index! >= 0 &&
        index! < DashboardPage.challans.length) {
      resolvedIndex = index!;
      resolvedChallan = Map<String, dynamic>.from(
        DashboardPage.challans[resolvedIndex],
      );
    } else if (DashboardPage.challans.isNotEmpty) {
      // fallback to first challan if available
      resolvedChallan = Map<String, dynamic>.from(DashboardPage.challans[0]);
      resolvedIndex = 0;
    } else {
      resolvedChallan = <String, dynamic>{};
      resolvedIndex = 0;
    }

    final amount = resolvedChallan['amount']?.toString() ?? '0';
    // Use a raw challan id internally (prefer explicit id field if present)
    final rawChallanId =
        (resolvedChallan['id']?.toString() ?? (resolvedIndex + 1).toString());
    // Display-friendly challan id for UI
    final challanId = 'CHALLAN_$rawChallanId';
    final violatorName = resolvedChallan['name'] ?? '';
    final violatorMobile = resolvedChallan['mobile'] ?? '';

    // Create PaymentPageView (BLoC removed - using PaymentService directly)
    return PaymentPageView(
      index: resolvedIndex,
      challan: resolvedChallan,
      amount: amount,
      challanId: challanId,
      rawChallanId: rawChallanId,
      violatorName: violatorName,
      violatorMobile: violatorMobile,
    );
  }
}

/// Payment Page View Widget - handles UI rendering
class PaymentPageView extends StatefulWidget {
  final int index;
  final Map<String, dynamic> challan;
  final String amount;
  final String challanId; // display id
  final String rawChallanId; // actual challan id to use as bill number
  final String violatorName;
  final String violatorMobile;

  const PaymentPageView({
    super.key,
    required this.index,
    required this.challan,
    required this.amount,
    required this.challanId,
    required this.rawChallanId,
    required this.violatorName,
    required this.violatorMobile,
  });

  @override
  State<PaymentPageView> createState() => _PaymentPageViewState();
}

class _PaymentPageViewState extends State<PaymentPageView> {
  late final IPaymentService _paymentService;
  bool _isProcessing = false;
  String _processingMessage = '';
  PaymentTransaction? _transaction;
  String? _errorMessage;
  bool _posNotInstalled = false;
  // Focus on card payment by default. Other methods can be enabled in config if needed.
  List<String> _availablePaymentMethods = ['CARD'];

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentServiceFactory.create(useMock: false);
    _checkPosAvailability();
  }

  Future<void> _checkPosAvailability() async {
    final installed = await _paymentService.isPosAppInstalled();
    setState(() {
      _posNotInstalled = !installed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      return _buildProcessingCard(_processingMessage.isNotEmpty
          ? _processingMessage
          : 'Processing...');
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
            _buildInfoRow("Challan ID", widget.challanId),
            _buildInfoRow("Violator Name", widget.violatorName),
            _buildInfoRow("Mobile", widget.violatorMobile),
            _buildInfoRow("Rule Violated", widget.challan['rule'] ?? ''),
          ],
        ),
      ),
    );
  }

  /// Build payment amount card
  Widget _buildPaymentAmountCard() {
    // Ensure the card expands to the full available width
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Payable Amount",
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                "₹${widget.amount}",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
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
            if (_availablePaymentMethods.contains('CARD'))
              _buildPaymentMethodButton(
                context: context,
                icon: Icons.credit_card,
                title: "Card Payment",
                subtitle: "Pay using debit/credit card via ICICI POS",
                color: Colors.blue,
                onTap: () => _startVizpaySale(context),
              ),

            if (_availablePaymentMethods.contains('CARD'))
              const SizedBox(height: 12),
            // QR Payment Option
            if (_availablePaymentMethods.contains('UPI'))
              _buildPaymentMethodButton(
                context: context,
                icon: Icons.qr_code,
                title: "UPI Payment",
                subtitle: "Pay using QR code scanning",
                color: Colors.teal,
                onTap: () => _processUpiPayment(context),
              ),

            const SizedBox(height: 12),

            // Cash Payment Option
            if (_availablePaymentMethods.contains('CASH'))
              _buildPaymentMethodButton(
                context: context,
                icon: Icons.money,
                title: "Cash Payment",
                subtitle: "Pay in cash and receive receipt",
                color: Colors.green,
                onTap: () => _processCashPayment(context),
              ),

            if (_availablePaymentMethods.contains('CASH'))
              const SizedBox(height: 12),

            /*    // BQR Payment Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.qr_code_scanner,
              title: "BQR Payment",
              subtitle: "Pay using Bharat QR code",
              color: Colors.orange,
              onTap: () => _processBqrPayment(context),
            );

            const SizedBox(height: 12),*/

            /*          // Cash at POS Option
            _buildPaymentMethodButton(
              context: context,
              icon: Icons.point_of_sale,
              title: "Cash at POS",
              subtitle: "Pay cash at POS terminal",
              color: Colors.brown,
              onTap: () => _processCashAtPosPayment(context),
            );*/

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

  /// Build UPI payment card with QR code
  Widget _buildUpiPaymentCard(BuildContext context, String qrData) {
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
                data: qrData,
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
                    onPressed: () {
                      // Cancel UPI flow and reset
                      setState(() {
                        _isProcessing = false;
                        _processingMessage = '';
                        _errorMessage = null;
                      });
                    },
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _processUpiPayment(context),
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
  Widget _buildSuccessCard(BuildContext context, PaymentTransaction transaction) {
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
              "Receipt Number: ${transaction.receiptNumber}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showReceiptDialog(context, widget.challan, transaction),
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

  /// Start card payment using PaymentService directly
  Future<void> _startCardPayment(BuildContext context) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Processing Card Payment...';
      _errorMessage = null;
    });

    // bill number should be the challan id itself
    final billNumber = widget.rawChallanId;

    final request = PosRequest(
      amount: widget.amount,
      tranType: 'SALE',
      billNumber: billNumber,
      sourceId: PaymentConfig.defaultConfig.sourceId,
      printFlag: '1',
      udf: {
        'UDF1': widget.rawChallanId,
        'UDF2': widget.violatorName,
        'UDF3': widget.violatorMobile,
        'UDF4': widget.challan['rule'] ?? '',
        'UDF5': 'MUNICIPAL_CHALLAN',
      },
    );

    try {
      final response = await _paymentService.processPayment(request);
      if (response.isSuccess) {
        final transaction = PaymentTransaction(
          transactionId: _generateTransactionId(),
          challanId: widget.rawChallanId,
          amount: widget.amount,
          paymentMethod: 'CARD',
          status: 'COMPLETED',
          timestamp: DateTime.now(),
          posResponse: response,
          receiptNumber: response.receiptData?['InvoiceNr']?.toString(),
        );

        setState(() {
          _transaction = transaction;
          _isProcessing = false;
        });

        DashboardPage.challans[widget.index]["status"] = "Paid";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment successful! Receipt: ${transaction.receiptNumber ?? ''}'),
          backgroundColor: Colors.green,
        ));
      } else {
        if (response.statusCode == 'MISSING_PLUGIN' ||
            (response.statusMessage?.toLowerCase().contains('plugin') ?? false)) {
          setState(() {
            _posNotInstalled = true;
            _isProcessing = false;
          });
        } else {
          setState(() {
            _errorMessage = response.statusMessage;
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: $e';
        _isProcessing = false;
      });
    }
  }

  /// Start Vizpay sale transaction (alias to _startCardPayment)
  void _startVizpaySale(BuildContext context) => _startCardPayment(context);

  /// UPI and cash handlers (simple simulations)
  void _processUpiPayment(BuildContext context) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Preparing UPI payment...';
      _errorMessage = null;
    });
    await Future.delayed(const Duration(seconds: 2));
    final transaction = PaymentTransaction(
      transactionId: _generateTransactionId(),
      challanId: widget.rawChallanId,
      amount: widget.amount,
      paymentMethod: 'UPI',
      status: 'COMPLETED',
      timestamp: DateTime.now(),
      receiptNumber: 'UPI_${DateTime.now().millisecondsSinceEpoch}',
    );
    setState(() {
      _transaction = transaction;
      _isProcessing = false;
    });
    DashboardPage.challans[widget.index]["status"] = "Paid";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('UPI payment completed: ${transaction.receiptNumber}'),
      backgroundColor: Colors.green,
    ));
  }

  void _processCashPayment(BuildContext context) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = 'Processing cash payment...';
      _errorMessage = null;
    });
    await Future.delayed(const Duration(seconds: 1));
    final transaction = PaymentTransaction(
      transactionId: _generateTransactionId(),
      challanId: widget.rawChallanId,
      amount: widget.amount,
      paymentMethod: 'CASH',
      status: 'COMPLETED',
      timestamp: DateTime.now(),
      receiptNumber: 'CASH_${DateTime.now().millisecondsSinceEpoch}',
    );
    setState(() {
      _transaction = transaction;
      _isProcessing = false;
    });
    DashboardPage.challans[widget.index]["status"] = "Paid";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Cash payment recorded: ${transaction.receiptNumber}'),
      backgroundColor: Colors.green,
    ));
  }

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN_${timestamp}_$random';
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
        Expanded(
          flex: 2,
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.grey[600]),
                SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
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
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

/// Show receipt dialog
Future<void> _showReceiptDialog(
  BuildContext context,
  Map<String, dynamic> challan, [
  PaymentTransaction? transaction,
]) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Divider(
                      thickness: 1.5,
                      color: Colors.grey[300],
                      height: 32,
                    ),
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
    );
  }

Future<void> _printReceipt(Map<String, dynamic> challan) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Center(
        child: pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
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
    );
  }

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
