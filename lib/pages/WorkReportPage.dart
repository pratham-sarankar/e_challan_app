import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WorkReportPage extends StatelessWidget {
  // Static report data
  final Map<String, dynamic> reportData = {
    'receivedChallans': 24,
    'unreceivedChallans': 5,
    'totalChallans': 29,
    'lastUpdated': DateTime.now(),
  };

  WorkReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Report'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                'Challan Summary',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            // Stats Cards
            Row(
              children: [
                _buildStatCard(
                  context,
                  title: 'Received',
                  value: reportData['receivedChallans'],
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
                SizedBox(width: 16),
                _buildStatCard(
                  context,
                  title: 'Pending',
                  value: reportData['unreceivedChallans'],
                  color: Colors.orange,
                  icon: Icons.pending,
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildStatCard(
              context,
              title: 'Total Challans',
              value: reportData['totalChallans'],
              color: Colors.indigo,
              icon: Icons.list_alt,
              fullWidth: true,
            ),

            // Recent Activity
            SizedBox(height: 32),
            Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, index) => Divider(height: 1),
                itemBuilder: (_, index) => _buildActivityItem(index),
              ),
            ),

            // Last Updated
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Last updated: ${DateFormat('MMM dd, yyyy - hh:mm a').format(reportData['lastUpdated'])}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int value,
    required Color color,
    required IconData icon,
    bool fullWidth = false,
  }) {
    return Expanded(
      flex: fullWidth ? 0 : 1,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {
        'action': 'Challan issued',
        'location': 'Main Road',
        'time': DateTime.now().subtract(Duration(minutes: 5)),
      },
      {
        'action': 'Payment received',
        'location': 'Market Area',
        'time': DateTime.now().subtract(Duration(hours: 2)),
      },
      {
        'action': 'Challan issued',
        'location': 'School Zone',
        'time': DateTime.now().subtract(Duration(hours: 5)),
      },
      {
        'action': 'Payment received',
        'location': 'Residential Area',
        'time': DateTime.now().subtract(Duration(days: 1)),
      },
      {
        'action': 'Challan issued',
        'location': 'Parking Lot',
        'time': DateTime.now().subtract(Duration(days: 2)),
      },
    ];

    final item = activities[index];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: item['action'].toString().contains('received')
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.blue.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          item['action'].toString().contains('received')
              ? Icons.attach_money
              : Icons.receipt,
          color: item['action'].toString().contains('received')
              ? Colors.green
              : Colors.blue,
        ),
      ),
      title: Text(
        item['action'].toString(),
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(item['location'].toString()),
      trailing: Text(
        DateFormat('hh:mm a').format(item['time'] as DateTime),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }
}
