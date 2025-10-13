import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/challan_type.dart';
import '../services/api_services.dart';

class InformationPage extends StatefulWidget {
  InformationPage({super.key});

  @override
  State<InformationPage> createState() => _InformationPageState();
}

class _InformationPageState extends State<InformationPage> {
  final List<Map<String, String>> rulesInfo = [
    {
      "rule": "C&D वेस्ट का सड़क पर निप्तारण",
      "amount": "₹ 2000",
      "reference": "Solid Waste Management Rules, 2016",
    },
    {
      "rule": "हरा/नीला/लाल डस्टबिन न रखना",
      "amount": "₹ 500",
      "reference": "नगर निगम अधिनियम धारा",
    },
    {
      "rule": "फुटपाथ पर गुमटी/ठेला लगान���",
      "amount": "₹ 1000",
      "reference": "अतिक्रमण अधिनियम",
    },
    {
      "rule": "प्रतिबंधित प्लास्टिक का उपयोग",
      "amount": "₹ 1500",
      "reference": "Plastic Waste Mgmt Rules, 2016",
    },
    {
      "rule": "बिना अनुमति व्यापार",
      "amount": "₹ 2500",
      "reference": "छ.ग. नगर पालिका निगम अधिनियम, धारा",
    },
  ];

  List<ChallanType> _challanTypes = [];
  bool _isLoadingTypes = false;
  String? _loadError;

  final ApiService _apiService = ApiService();
  Timer? _prefsPollTimer;

  @override
  void initState() {
    super.initState();
    // Initialize loading logic asynchronously so we can check whether an
    // access token already exists before calling _loadChallanTypes. This
    // prevents the page from calling the API twice (once immediately and
    // again from the prefs poll).
    _initLoad();
  }

  // Async initialization that checks for an existing token and only starts
  // the polling timer when a token is not present. This avoids duplicate
  // calls to _loadChallanTypes.
  Future<void> _initLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null && token.isNotEmpty) {
      // Token already available: load once and don't start the polling timer.
      if (mounted) await _loadChallanTypes();
      return;
    }

    // No token yet: start a short-lived polling timer which will call
    // _loadChallanTypes when the token becomes available. The timer is
    // canceled as soon as the token appears.
    _prefsPollTimer = Timer.periodic(Duration(seconds: 1), (t) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        t.cancel();
        _prefsPollTimer = null;
        // Give a tiny delay to allow other parts of the app to finish storing state
        await Future.delayed(Duration(milliseconds: 200));
        if (mounted) await _loadChallanTypes();
      }
    });
  }

  /// Load challan types with a small retry strategy for transient auth/timing issues.
  /// If the access token hasn't been saved yet the server may return 401; this
  /// will retry a few times before surfacing an error.
  Future<void> _loadChallanTypes([int attempt = 0]) async {
    // Prevent concurrent/duplicate loads: if a load is already in progress
    // and this isn't an explicit retry attempt, skip starting another one.
    if (_isLoadingTypes && attempt == 0) {
      print('[InformationPage] skipping duplicate load (already loading)');
      return;
    }
    setState(() {
      _isLoadingTypes = true;
      _loadError = null;
    });
    try {
      final types = await _apiService.getChallanTypes();
      print('[InformationPage] loaded challan types count=${types.length}');
      for (final t in types)
        print('[InformationPage] type=${t.typeName} fine=${t.fineAmount}');
      if (mounted) {
        setState(() => _challanTypes = types);
      }
      // Show a small confirmation like AddChallanPage so devs/testers know the load succeeded
    } catch (e) {
      print('[InformationPage] failed to load challan types: ${e.toString()}');

      // If the server returned a 401 (or similar auth error) retry a few times
      final status = _apiService.getLastChallanTypesStatus();
      if ((status == 401 || status == 0) && attempt < 3) {
        final nextAttempt = attempt + 1;
        print(
          '[InformationPage] retrying challan types (attempt $nextAttempt)',
        );
        await Future.delayed(Duration(milliseconds: 800));
        if (mounted) await _loadChallanTypes(nextAttempt);
        return;
      }

      if (mounted) setState(() => _loadError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingTypes = false);
    }
  }

  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('access_token cleared')));
    await _loadChallanTypes();
  }

  @override
  void dispose() {
    _prefsPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rule Violation Info"),
        // Small dev/test action to clear the stored token and trigger the loader.
        actions: [
          IconButton(
            tooltip: 'Clear access token',
            icon: Icon(Icons.delete_forever),
            onPressed: _clearStoredToken,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challan Types',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (_isLoadingTypes)
                    return Center(child: CircularProgressIndicator());
                  if (_loadError != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Error loading challan types'),
                          SizedBox(height: 8),
                          Text(
                            _loadError!,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _loadChallanTypes,
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (_challanTypes.isEmpty)
                    return Center(child: Text('No challan types available'));

                  return ListView.builder(
                    itemCount: _challanTypes.length,
                    itemBuilder: (context, index) {
                      final c = _challanTypes[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            c.typeName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(c.description),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${c.fineAmount}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                c.isActive,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Text(
            //   'Sample Rules',
            //   style: Theme.of(context).textTheme.titleMedium,
            // ),
            // SizedBox(height: 8),
            // Container(
            //   height: 150,
            //   child: ListView.builder(
            //     itemCount: rulesInfo.length,
            //     itemBuilder: (context, index) {
            //       final rule = rulesInfo[index];
            //       return ListTile(
            //         dense: true,
            //         title: Text(
            //           rule["rule"]!,
            //           style: TextStyle(
            //             fontWeight: FontWeight.bold,
            //             fontSize: 12,
            //           ),
            //         ),
            //         subtitle: Text(
            //           'Ref: ${rule["reference"]}',
            //           style: TextStyle(fontSize: 11),
            //         ),
            //         trailing: Text(
            //           rule["amount"]!,
            //           style: TextStyle(color: Colors.green, fontSize: 12),
            //         ),
            //       );
            //     },
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
