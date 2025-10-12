import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:animate_do/animate_do.dart';
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = now.subtract(Duration(days: 30));
    _toDate = now;
    _loadChallans();
  }

  Future<void> _loadChallans() async {
    await Future.delayed(Duration(milliseconds: 1000)); // Simulate loading
    setState(() {
      _filteredChallans = DashboardPage.challans;
      _isLoading = false;
    });
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
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
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
                        color: Colors.black.withOpacity(0.05),
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
          Lottie.asset(
            'assets/animations/empty.json',
            width: 200,
            height: 200,
            repeat: true,
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
                    ? Colors.green.withOpacity(0.05)
                    : Colors.orange.withOpacity(0.05),
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
                      color: statusColor.withOpacity(0.1),
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

  void _showChallanDetails(
    BuildContext context,
    Map<String, dynamic> challan,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                          onPressed: () => Navigator.pop(context),
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
                              DateFormat('dd/MM/yyyy').format(DateTime.now()),
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
                      if (challan["images"]?.isNotEmpty ?? false) ...[
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
                          children: (challan["images"] as List)
                              .map<Widget>(
                                (img) => ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    img,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
                          Navigator.pop(context);
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
                      onPressed: () => Navigator.pop(context),
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

  TableRow _buildTableRow(String label, String value, {bool isStatus = false}) {
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
            value,
            style: TextStyle(
              fontWeight: isStatus ? FontWeight.bold : FontWeight.normal,
              color: isStatus
                  ? value == "Paid"
                        ? Colors.green
                        : Colors.orange
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
}
