import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const EpiDashApp());
}

class EpiDashApp extends StatelessWidget {
  const EpiDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EpiDash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _airQualityRecords = [];
  bool _isLoading = true;
  String _selectedCity = 'edmonton';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    // Inject the selected city directly into the sync URL
    final syncUrl = Uri.parse('http://10.0.2.2:5156/api/AirQuality/sync/$_selectedCity'); 
    final fetchUrl = Uri.parse('http://10.0.2.2:5156/api/AirQuality'); 
    
    try {
      // 1. Trigger the C# backend to pull live data from Open-Meteo
      await http.post(syncUrl);

      // 2. Fetch the newly updated database list
      final response = await http.get(fetchUrl);

      if (response.statusCode == 200) {
        setState(() {
          // Decode the data and reverse it so the newest syncs appear at the top
          _airQualityRecords = json.decode(response.body);
          _airQualityRecords = _airQualityRecords.reversed.toList();
          _isLoading = false;
        });
      } else {
        debugPrint('Server returned an error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Network error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EpiDash Live Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // The City Selection Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: const Text('Edmonton'),
                  selected: _selectedCity == 'edmonton',
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() => _selectedCity = 'edmonton');
                      _fetchData();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Calgary'),
                  selected: _selectedCity == 'calgary',
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() => _selectedCity = 'calgary');
                      _fetchData();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Vancouver'),
                  selected: _selectedCity == 'vancouver',
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() => _selectedCity = 'vancouver');
                      _fetchData();
                    }
                  },
                ),
              ],
            ),
          ),
          
          // The Pull-to-Refresh List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _airQualityRecords.isEmpty
                    ? const Center(child: Text('No data found in database.'))
                    : RefreshIndicator(
                        onRefresh: _fetchData, 
                        color: Colors.teal,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even if the list is small
                          padding: const EdgeInsets.all(16),
                          itemCount: _airQualityRecords.length,
                          itemBuilder: (context, index) {
                            final record = _airQualityRecords[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: const Icon(Icons.air, color: Colors.teal, size: 36),
                                title: Text(record['locationName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('AQI: ${record['airQualityIndex']} | PM2.5: ${record['pm25Level']}'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DetailsScreen(record: record),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final dynamic record;

  const DetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    // Parse the date to make it look a bit cleaner
    DateTime parsedDate = DateTime.parse(record['recordDate']);
    String formattedDate = '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} at ${parsedDate.hour}:${parsedDate.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(record['locationName'], style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Air Quality Index', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              record['airQualityIndex'].toString(), 
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.teal)
            ),
            const Divider(height: 48, thickness: 1),
            
            const Text('PM 2.5 Concentration', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              '${record['pm25Level']} µg/m³', 
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600)
            ),
            const Divider(height: 48, thickness: 1),

            const Text('Last Synced', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              formattedDate, 
              style: const TextStyle(fontSize: 20)
            ),
          ],
        ),
      ),
    );
  }
}