import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:municipal_e_challan/models/challan_response.dart';
import 'package:municipal_e_challan/pages/payment_page.dart';
import 'package:municipal_e_challan/services/api_services.dart';

class ChallanDetailsPage extends StatefulWidget {
  final ChallanResponse challan;

  const ChallanDetailsPage({super.key, required this.challan});

  @override
  ChallanDetailsPageState createState() => ChallanDetailsPageState();
}

class ChallanDetailsPageState extends State<ChallanDetailsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // Transactions state
  bool _isTransLoading = true;
  String? _transError;
  List<Map<String, dynamic>> _transactions = [];
  num _totalAmount = 0;
  Map<String, dynamic>? _statusSummary;
  int _transactionCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchServerImages();
    _fetchTransactions();
  }

  Future<void> _fetchServerImages() async {
    setState(() => _isLoading = true);
    try {
      final int fetchId = widget.challan.challanId;
      if (fetchId > 0) {
        final result = await _apiService.getChallanImageObjects(fetchId);
        setState(() {
          widget.challan.imageUrls = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load evidence images: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isTransLoading = true;
      _transError = null;
    });
    try {
      final int fetchId = widget.challan.challanId;
      if (fetchId > 0) {
        final data = await _apiService.getChallanTransactions(fetchId);
        // Safely extract expected fields
        final txs = (data['transactions'] is List)
            ? data['transactions'] as List
            : <dynamic>[];
        _transactions = txs
            .where((e) => e != null)
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map<String, dynamic>),
            )
            .toList();
        _totalAmount = (data['total_amount'] is num)
            ? data['total_amount'] as num
            : num.tryParse('${data['total_amount']}') ?? 0;
        _statusSummary = (data['status_summary'] is Map<String, dynamic>)
            ? data['status_summary'] as Map<String, dynamic>
            : null;
        _transactionCount = (data['transaction_count'] is int)
            ? data['transaction_count'] as int
            : _transactions.length;
      } else {
        _transactions = [];
        // no transactions; keep list empty
        _totalAmount = 0;
        _statusSummary = null;
        _transactionCount = 0;
      }
    } catch (e) {
      _transError = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transactions: ${e.toString()}'),
          ),
        );
      }
      setState(() {
        _transactions = [];
        _totalAmount = 0;
        _statusSummary = null;
        _transactionCount = 0;
      });
    } finally {
      if (mounted) setState(() => _isTransLoading = false);
    }
  }

  Widget _buildImageWidget(dynamic img) {
    try {
      if (img == null) return Container(color: Colors.grey[200]);

      if (img is String) {
        return Image.network(
          img,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, st) => Container(
            color: Colors.grey[200],
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      }

      if (img is ImageProvider) return Image(image: img, fit: BoxFit.cover);

      if (img is File) return Image.file(img, fit: BoxFit.cover);

      final dynamic maybePath = (img as dynamic).path;
      if (maybePath is String && maybePath.isNotEmpty) {
        return Image.file(File(maybePath), fit: BoxFit.cover);
      }
    } catch (_) {}
    return Container(color: Colors.grey[200]);
  }

  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: EdgeInsets.only(bottom: 12),
            child: Card(
              elevation: 0,
              color: Colors.white,
              child: Container(
                height: 80,
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageShimmer() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(
        4,
        (index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(width: 100, height: 100, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection() {
    if (_isTransLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: _buildShimmerEffect(),
      );
    }

    if (_transError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to load transactions',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 12),
                Text(
                  'No transactions found',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This challan has no payment transactions yet.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),

        // Transaction Summary
        if (_statusSummary != null && _statusSummary!.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Transaction Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _statusSummary!.entries.map((entry) {
                    Color statusColor;
                    String statusLabel;
                    switch (entry.key.toLowerCase()) {
                      case 'paid':
                      case 'success':
                      case 'completed':
                        statusColor = Colors.green;
                        statusLabel = 'Paid';
                        break;
                      case 'failed':
                      case 'cancelled':
                      case 'declined':
                        statusColor = Colors.red;
                        statusLabel = 'Failed';
                        break;
                      case 'pending':
                      case 'processing':
                        statusColor = Colors.orange;
                        statusLabel = 'Pending';
                        break;
                      default:
                        statusColor = Colors.grey;
                        statusLabel = entry.key.toString();
                    }

                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$statusLabel: ${entry.value}',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Total amount and count
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '₹${_totalAmount.toString()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$_transactionCount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Transactions list
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _transactions.length,
          separatorBuilder: (_, __) => SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final tx = _transactions[i];
            final amt =
                tx['amount'] ?? tx['paid_amount'] ?? tx['payment_amount'] ?? '';
            final status =
                tx['order_status'] ??
                tx['status'] ??
                tx['payment_status'] ??
                '';
            final method = tx['payment_method'] ?? tx['method'] ?? '';
            final id = tx['id'] ?? tx['transaction_id'] ?? '';
            final orderId = tx['order_id'] ?? '';
            String dateStr = '';
            final rawDate =
                tx['created_at'] ??
                tx['paid_at'] ??
                tx['timestamp'] ??
                tx['date'];
            if (rawDate != null) {
              try {
                final dt = DateTime.parse(rawDate.toString());
                dateStr = DateFormat('dd/MM/yyyy HH:mm').format(dt);
              } catch (_) {
                dateStr = rawDate.toString();
              }
            }

            // Determine status color and display text
            Color statusColor;
            String statusText = status.toString().toUpperCase();
            switch (status.toString().toLowerCase()) {
              case 'paid':
              case 'success':
              case 'completed':
                statusColor = Colors.green;
                statusText = 'PAID';
                break;
              case 'failed':
              case 'cancelled':
              case 'declined':
                statusColor = Colors.red;
                statusText = 'FAILED';
                break;
              case 'pending':
              case 'processing':
                statusColor = Colors.orange;
                statusText = 'PENDING';
                break;
              default:
                statusColor = Colors.grey;
                statusText = status.toString().toUpperCase();
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount and status row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${amt.toString()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.grey[800],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Transaction details
                    if (method.toString().isNotEmpty)
                      _buildTransactionDetail(
                        Icons.payment,
                        'Payment Method',
                        method.toString(),
                      ),
                    if (dateStr.isNotEmpty)
                      _buildTransactionDetail(
                        Icons.access_time,
                        'Date & Time',
                        dateStr,
                      ),
                    if (orderId.isNotEmpty)
                      _buildTransactionDetail(
                        Icons.receipt,
                        'Order ID',
                        orderId,
                      ),
                    _buildTransactionDetail(
                      Icons.tag,
                      'Transaction ID',
                      '#${id.toString()}',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTransactionDetail(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEvidence = widget.challan.imageUrls.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Challan Details',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        // backgroundColor: Colors.white,
        // elevation: 0,
        // shadowColor: Colors.grey.withOpacity(0.1),
        // surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challan Info Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with challan ID
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Challan ID',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '#${widget.challan.challanId}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Details table
                      Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Date',
                              widget.challan.createdAt,
                              Icons.calendar_today,
                            ),
                            _buildDetailRow(
                              'Name',
                              widget.challan.fullName,
                              Icons.person,
                            ),
                            _buildDetailRow(
                              'Mobile',
                              widget.challan.contactNumber,
                              Icons.phone,
                            ),
                            _buildDetailRow(
                              'Amount',
                              '₹${widget.challan.fineAmount}',
                              Icons.account_balance_wallet,
                              valueColor: Colors.red[600],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Evidence Images Section
                if (hasEvidence || _isLoading) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.photo_library,
                              color: Colors.blue[600],
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'EVIDENCE IMAGES',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (_isLoading)
                          _buildImageShimmer()
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ...widget.challan.imageUrls.map<Widget>(
                                (img) => Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 110,
                                      height: 110,
                                      child: _buildImageWidget(img),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],

                // Transactions section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Colors.blue[600],
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'TRANSACTIONS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      _buildTransactionsSection(),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Pay Now Button
                if (_totalAmount < widget.challan.fineAmount)
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[600]!, Colors.green[700]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.payment, size: 24, color: Colors.white),
                      label: Text(
                        'PAY NOW',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PaymentPage(challan: widget.challan),
                          ),
                        );
                      },
                    ),
                  ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    dynamic value,
    IconData icon, {
    Color? valueColor,
  }) {
    final String text = value?.toString() ?? '-';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[800],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
