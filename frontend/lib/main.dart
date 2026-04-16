import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // We use 10.0.2.2 so the emulator can talk to your laptop's localhost!
    // NOTE: Make sure the port 5123 matches your C# API terminal
    final url = Uri.parse('http://10.0.2.2:5156/api/AirQuality'); 
    
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _airQualityRecords = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        print('Server returned an error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error: $e');
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _airQualityRecords.isEmpty
              ? const Center(child: Text('No data found in database.'))
              : ListView.builder(
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
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}