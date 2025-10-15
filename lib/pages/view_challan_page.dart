import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:municipal_e_challan/models/challan_response.dart';
import 'package:municipal_e_challan/services/api_services.dart';
import 'package:shimmer/shimmer.dart';

import 'challan_details_page.dart';

class ViewChallanPage extends StatefulWidget {
  const ViewChallanPage({super.key});

  @override
  ViewChallanPageState createState() => ViewChallanPageState();
}

class ViewChallanPageState extends State<ViewChallanPage> {
  List<ChallanResponse> _challans = [];
  bool _isLoading = true;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadChallans();
  }

  Future<void> _loadChallans() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getChallans();
      setState(() {
        _challans = list;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load challans: ${e.toString()}')),
        );
      }
      setState(() {
        _challans = [];
        _isLoading = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Previous Challans"), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildShimmerList()
                : _challans.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: _challans.length,
                    separatorBuilder: (_, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[300],
                    ),
                    itemBuilder: (_, index) {
                      final challan = _challans[index];
                      return Dismissible(
                        key: ValueKey(challan.id),
                        direction: DismissDirection.endToStart,
                        // Add a small resizeDuration to make removal feel snappier
                        resizeDuration: Duration(milliseconds: 250),
                        // Make the background visually match the Card (rounded + shadow + icon + label)
                        background: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.12),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
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
                                FilledButton(
                                  child: Text('DELETE'),
                                  onPressed: () => Navigator.pop(c, true),
                                ),
                              ],
                            ),
                          );
                          return confirmed == true;
                        },
                        onDismissed: (direction) async {
                          // Optimistically remove from UI and attempt server deletion. If it fails, rollback.
                          final removed = _challans.removeAt(index);
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
                              _challans.insert(index, removed);
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
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              child: Text(
                                challan.name.isNotEmpty
                                    ? challan.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            onTap: () {
                              _showChallanDetails(context, challan);
                            },
                            title: Text(challan.name),
                            subtitle: Text("Rule: ${challan.rule}"),
                            trailing: Text(
                              "₹${challan.amount}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_challans.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Note: Swipe  left to delete a challan",
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, __) =>
          Divider(height: 1, thickness: 1, color: Colors.grey[300]),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          title: Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Container(
            height: 14,
            width: 120,
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          trailing: Container(
            height: 16,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
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
            'Previous challans will appear here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Future<void> _showChallanDetails(
    BuildContext context,
    ChallanResponse challan,
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
