import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:municipal_e_challan/models/challan_response.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'challan_details_page.dart';

class ViewChallanPage extends StatefulWidget {
  const ViewChallanPage({super.key});

  @override
  _ViewChallanPageState createState() => _ViewChallanPageState();
}

class _ViewChallanPageState extends State<ViewChallanPage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  List<ChallanResponse> _filteredChallans = [];
  bool _isLoading = true;

  // Controls whether the small 'swipe to delete' hint is shown
  bool _showSwipeHint = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = now.subtract(Duration(days: 30));
    _toDate = now;
    _loadSwipeHintPref();
    _loadChallans();
  }

  // Load persisted flag to decide whether to show the swipe hint
  Future<void> _loadSwipeHintPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool('seen_swipe_hint') ?? false;
      if (mounted) {
        setState(() => _showSwipeHint = !seen);
      }
    } catch (_) {
      // ignore and keep default true
    }
  }

  // Persist that the user has seen/dismissed the swipe hint
  Future<void> _setSwipeHintSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_swipe_hint', true);
    } catch (_) {}
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
          final createdRaw = c.createdAt;
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
        _filteredChallans = [];
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
            // Small hint to let users know they can swipe a challan to delete it.
            if (_showSwipeHint)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.swipe,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Swipe right on a challan to delete it',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 18),
                          onPressed: () {
                            // Persist dismissal and hide the hint
                            _setSwipeHintSeen();
                            setState(() => _showSwipeHint = false);
                          },
                          tooltip: 'Dismiss',
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
                        final challan = _filteredChallans[index];
                        final keyVal = ValueKey(challan.id);

                        return Dismissible(
                          key: keyVal,
                          direction: DismissDirection.startToEnd,
                          // Add a small resizeDuration to make removal feel snappier
                          resizeDuration: Duration(milliseconds: 250),
                          // Make the background visually match the Card (rounded + shadow + icon + label)
                          background: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.12),
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(left: 20),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            // Ask for confirmation before deleting
                            final bool? confirmed = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: Text('Delete challan?'),
                                content: Text(
                                  'This will permanently delete the selected challan.',
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('CANCEL'),
                                    onPressed: () => Navigator.pop(c, false),
                                  ),
                                  TextButton(
                                    child: Text(
                                      'DELETE',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () => Navigator.pop(c, true),
                                  ),
                                ],
                              ),
                            );
                            return confirmed == true;
                          },
                          onDismissed: (direction) async {
                            // Mark the hint as seen when the user performs a delete action
                            _setSwipeHintSeen();
                            // Optimistically remove from UI and attempt server deletion. If it fails, rollback.
                            final removed = _filteredChallans.removeAt(index);
                            setState(() {});

                            final int fetchId = removed.id;

                            // Show progress while deleting
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) =>
                                  Center(child: CircularProgressIndicator()),
                            );

                            try {
                              if (fetchId > 0) {
                                await _apiService.deleteChallan(fetchId);
                              }

                              Navigator.pop(context); // remove progress dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Challan deleted')),
                              );
                            } catch (e) {
                              Navigator.pop(context); // remove progress dialog

                              // Rollback UI
                              setState(() {
                                _filteredChallans.insert(index, removed);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to delete challan: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          },
                          child: FadeInUp(
                            duration: Duration(milliseconds: 400),
                            delay: Duration(milliseconds: index * 100),
                            child: _buildChallanCard(challan, index),
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

  Widget _buildChallanCard(ChallanResponse challan, int index) {
    // Status removed from challan UI because API does not return a `status` field.
    // Use a neutral color for the card.
    final statusColor = Colors.orange;

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
              colors: [Colors.white, Colors.orange.withAlpha(13)],
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
                      challan.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Rule: ${challan.rule}",
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
                    "₹${challan.amount}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
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
    ChallanResponse challan,
    int index,
  ) async {
    // Navigate to the new full-screen ChallanDetailsPage instead of showing a dialog
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChallanDetailsPage(challan: challan)),
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
