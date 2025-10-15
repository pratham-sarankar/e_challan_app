import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  Widget _buildTransactionsSection() {
    if (_isTransLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_transError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          'Failed to load transactions',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          Text(
            'No transactions found for this challan.',
            style: TextStyle(color: Colors.grey[700]),
          ),
          SizedBox(height: 6),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        // Transaction Summary
        if (_statusSummary != null && _statusSummary!.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 12,
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
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
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
                          SizedBox(width: 6),
                          Text(
                            '$statusLabel: ${entry.value}',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount: ₹${_totalAmount.toString()}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Text(
              'Transactions: $_transactionCount',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _transactions.length,
          separatorBuilder: (_, __) => SizedBox(height: 4),
          itemBuilder: (ctx, i) {
            final tx = _transactions[i];
            final amt =
                tx['amount'] ?? tx['paid_amount'] ?? tx['payment_amount'] ?? '';
            // Use order_status from API response as the primary status field
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

            return Card(
              margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
              elevation: 1,
              child: ListTile(
                title: Row(
                  children: [
                    Text(
                      '₹${amt.toString()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (method.toString().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              method.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (dateStr.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (orderId.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Order: $orderId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Transaction ID: #${id.toString()}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
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

  TableRow _buildTableRow(
    String label,
    dynamic value, {
    bool isStatus = false,
  }) {
    final String text = value?.toString() ?? '-';
    final bool paid = text.toLowerCase() == 'paid';
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
              color: isStatus
                  ? (paid ? Colors.green : Colors.orange)
                  : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasEvidence = widget.challan.imageUrls.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('Challan Details')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Table(
                    columnWidths: {
                      0: FlexColumnWidth(1.5),
                      1: FlexColumnWidth(2.5),
                    },
                    children: [
                      _buildTableRow(
                        'Challan ID:',
                        '#${widget.challan.challanId}',
                      ),
                      _buildTableRow('Date', widget.challan.createdAt),
                      _buildTableRow('Name', widget.challan.fullName),
                      _buildTableRow('Mobile', widget.challan.contactNumber),
                      // TODO: Fetch challan type and create a global provider so we can access it from anywhere
                      // Right now we have only the challanTypeId
                      // _buildTableRow('Rule Violated', widget.challan.challanTypeId),
                      _buildTableRow(
                        'Fine Amount',
                        '₹${widget.challan.fineAmount}',
                      ),
                      // TODO: check if the API returns notes or description, if yes, display it here.
                      // _buildTableRow('Notes', widget.challan.notes ?? '-'),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                if (hasEvidence) ...[
                  Text(
                    'EVIDENCE IMAGES',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...widget.challan.imageUrls.map<Widget>(
                        (img) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: _buildImageWidget(img),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 20),
                // Transactions section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRANSACTIONS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      _buildTransactionsSection(),
                    ],
                  ),
                ),
                SizedBox(height: 40),
                if (_totalAmount < widget.challan.fineAmount)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.payment, size: 20),
                      label: Text(
                        'PAY NOW',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
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
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black12,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
