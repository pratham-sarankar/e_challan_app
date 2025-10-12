import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:shimmer/shimmer.dart';

import 'dashboard_page.dart';
import 'payment_page.dart';

class ViewChallanPage extends StatefulWidget {
  const ViewChallanPage({super.key});

  @override
  _ViewChallanPageState createState() => _ViewChallanPageState();
}

class _ViewChallanPageState extends State<ViewChallanPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  List<Map<String, dynamic>> _filteredChallans = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = now.subtract(Duration(days: 30));
    _toDate = now;
    _loadChallans();
  }

  Future<void> _loadChallans() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getChallans();

      // Apply date filtering if both dates are present
      var results = list;
      if (_fromDate != null && _toDate != null) {
        final from = DateTime(
          _fromDate!.year,
          _fromDate!.month,
          _fromDate!.day,
        );
        final to = DateTime(
          _toDate!.year,
          _toDate!.month,
          _toDate!.day,
          23,
          59,
          59,
        );
        results = results.where((c) {
          final createdRaw = c['created_at'] ?? c['createdAt'] ?? '';
          try {
            final dt = DateTime.parse(createdRaw.toString());
            return !dt.isBefore(from) && !dt.isAfter(to);
          } catch (_) {
            // If created_at not parseable, keep the item (avoid accidental drop)
            return true;
          }
        }).toList();
      }

      setState(() {
        _filteredChallans = results;
        _isLoading = false;
      });
    } catch (e) {
      // Fall back to local in-memory list and notify the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load challans: ${e.toString()}')),
        );
      }
      setState(() {
        _filteredChallans = DashboardPage.challans;
        _isLoading = false;
      });
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _fromDate ?? DateTime.now().subtract(Duration(days: 30)),
        end: _toDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
        _isLoading = true;
      });
      _loadChallans();
    }
  }

  void _resetDates() {
    setState(() {
      _fromDate = DateTime.now().subtract(Duration(days: 30));
      _toDate = DateTime.now();
      _isLoading = true;
    });
    _loadChallans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Previous Challans"),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _showDateRangePicker,
            tooltip: "Select Date Range",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(13),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Column(
          children: [
            FadeInDown(
              duration: Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _showDateRangePicker,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.date_range,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  _fromDate != null && _toDate != null
                                      ? '${DateFormat('dd MMM').format(_fromDate!)} - ${DateFormat('dd MMM yyyy').format(_toDate!)}'
                                      : 'Select Date Range',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _fromDate != null
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_fromDate != null || _toDate != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          child: TextButton.icon(
                            icon: Icon(
                              Icons.refresh,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            label: Text(
                              'Reset',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            onPressed: _resetDates,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? _buildShimmerList()
                  : _filteredChallans.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: EdgeInsets.all(16),
                      itemCount: _filteredChallans.length,
                      separatorBuilder: (_, index) => SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        return FadeInUp(
                          duration: Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 100),
                          child: _buildChallanCard(
                            _filteredChallans[index],
                            index,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The original Lottie animation file is not present in the project.
          // Fallback to a bundled static image that conveys an empty state.
          // `assets/images/clean_city.png` exists in the repo.
          Image.asset(
            'assets/images/clean_city.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 24),
          Text(
            'No challans found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildChallanCard(Map<String, dynamic> challan, int index) {
    final isPaid = challan["status"] == "Paid";
    final statusColor = isPaid ? Colors.green : Colors.orange;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showChallanDetails(context, challan, index),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                isPaid
                    ? Colors.green.withAlpha(13)
                    : Colors.orange.withAlpha(13),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challan["name"],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Rule: ${challan['rule']}",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${challan['amount']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      challan["status"],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChallanDetails(
    BuildContext context,
    Map<String, dynamic> challan,
    int index,
  ) async {
    // Show temporary loading while fetching images
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );

    List<String> serverImageUrls = [];
    try {
      final int fetchId = (challan['challan_id'] ?? challan['id'] ?? 0) as int;
      if (fetchId > 0) {
        serverImageUrls = await _apiService.getChallanImages(fetchId);
      }
    } catch (e) {
      // show a non-blocking message; we'll fall back to existing fields
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load evidence images: ${e.toString()}'),
          ),
        );
      }
    }

    // remove loading indicator
    Navigator.pop(context);

    // Merge server-provided URLs (if any) with any existing image_urls on the challan.
    final List<String> serverUrlsClean = serverImageUrls
        .where((s) => s.isNotEmpty)
        .toList();
    final List<String> existingUrls =
        (challan['image_urls'] as List?)
            ?.map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    final List<String> detailImageUrls = serverUrlsClean.isNotEmpty
        ? serverUrlsClean
        : existingUrls;
    // compute evidence presence here (non-nullable) so it can be used inside the widget tree
    final bool hasEvidence =
        detailImageUrls.isNotEmpty ||
        ((challan['images'] as List?)?.isNotEmpty ?? false);

    // Now show the dialog using the resolved `detailImageUrls` list for server images.
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "CHALLAN DETAILS",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.print, color: Colors.white),
                            onPressed: () => _printChallan(context, challan),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
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
                              _buildTableRow("Challan No.", "#${index + 1}"),
                              _buildTableRow(
                                "Date",
                                // Prefer server-provided created_at; fall back to now
                                (() {
                                  final createdRaw =
                                      challan['created_at'] ??
                                      challan['createdAt'] ??
                                      '';
                                  try {
                                    final dt = DateTime.parse(
                                      createdRaw.toString(),
                                    );
                                    return DateFormat('dd/MM/yyyy').format(dt);
                                  } catch (_) {
                                    return DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(DateTime.now());
                                  }
                                })(),
                              ),
                              _buildTableRow(
                                "Status",
                                challan['status'],
                                isStatus: true,
                              ),
                              _buildTableRow("Name", challan['name']),
                              _buildTableRow("Mobile", challan['mobile']),
                              _buildTableRow("Address", challan['address']),
                              _buildTableRow("Rule Violated", challan['rule']),
                              _buildTableRow(
                                "Fine Amount",
                                "₹${challan['amount']}",
                              ),
                              _buildTableRow("Notes", challan['notes'] ?? '-'),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),
                        // Show evidence images: prefer `detailImageUrls` (server GET /images),
                        // otherwise fall back to local `challan['images']` files.
                        if (hasEvidence) ...[
                          Text(
                            "EVIDENCE IMAGES",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // Show server image URLs first
                              ...detailImageUrls.map<Widget>(
                                (url) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx2, err, st) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // If there are local images (File/ImageProvider), render them too
                              ...((challan['images'] as List?) ?? [])
                                  .map<Widget>(
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
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (challan["status"] != "Paid")
                        ElevatedButton.icon(
                          icon: Icon(Icons.payment, size: 20),
                          label: Text(
                            "PAY NOW",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentPage(index: index),
                              ),
                            );
                          },
                        ),
                      SizedBox(width: 12),
                      OutlinedButton(
                        child: Text("CLOSE"),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  void _printChallan(BuildContext context, Map<String, dynamic> challan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Printing feature will be implemented soon",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  // Helper to render various image representations stored in challan['images']
  // analyzer may occasionally report this as unused in some environments; ignore that warning
  // ignore: unused_element
  Widget _buildImageWidget(dynamic img) {
    try {
      if (img == null) {
        return Container(color: Colors.grey[200]);
      }

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

      if (img is ImageProvider) {
        return Image(image: img, fit: BoxFit.cover);
      }

      if (img is File) {
        return Image.file(img, fit: BoxFit.cover);
      }

      // Some older code may store an object with a `path` property
      final dynamic maybePath = (img as dynamic).path;
      if (maybePath is String && maybePath.isNotEmpty) {
        return Image.file(File(maybePath), fit: BoxFit.cover);
      }
    } catch (_) {}

    return Container(color: Colors.grey[200]);
  }
}
