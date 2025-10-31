import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/challan_type.dart';
import '../services/api_services.dart';
import '../services/service_locator.dart';
import '../cubits/challan_types_cubit.dart';
import '../cubits/challan_types_state.dart';

class InformationPage extends StatefulWidget {
  const InformationPage({super.key});

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

  late ChallanTypesCubit _cubit;
  Timer? _prefsPollTimer;

  @override
  void initState() {
    super.initState();
    // Get the global cubit from service locator
    _cubit = getIt<ChallanTypesCubit>();
    
    // If challan types haven't been loaded yet, load them now
    if (_cubit.state is ChallanTypesInitial) {
      _initLoad();
    }
  }

  // Async initialization that checks for an existing token and loads if needed
  Future<void> _initLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token != null && token.isNotEmpty) {
      // Token available: load challan types via global cubit
      _cubit.loadChallanTypes();
    } else {
      // No token yet: start a short-lived polling timer
      _prefsPollTimer = Timer.periodic(Duration(seconds: 1), (t) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null && token.isNotEmpty) {
          t.cancel();
          _prefsPollTimer = null;
          // Give a tiny delay to allow other parts of the app to finish storing state
          await Future.delayed(Duration(milliseconds: 200));
          if (mounted) _cubit.loadChallanTypes();
        }
      });
    }
  }

  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('access_token cleared')));
    _cubit.loadChallanTypes();
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
              child: BlocBuilder<ChallanTypesCubit, ChallanTypesState>(
                bloc: _cubit,
                builder: (context, state) {
                  if (state is ChallanTypesLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (state is ChallanTypesError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Error loading challan types'),
                          SizedBox(height: 8),
                          Text(
                            state.message,
                            style: TextStyle(color: Colors.red),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _cubit.retry(),
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is ChallanTypesLoaded) {
                    final challanTypes = state.challanTypes;
                    if (challanTypes.isEmpty) {
                      return Center(child: Text('No challan types available'));
                    }

                    return ListView.builder(
                      itemCount: challanTypes.length,
                      itemBuilder: (context, index) {
                        final c = challanTypes[index];
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
                  }

                  // Initial or unknown state
                  return Center(child: Text('Loading...'));
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
