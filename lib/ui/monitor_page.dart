import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/monitoring_service.dart';

class MonitorPage extends StatefulWidget {
  const MonitorPage({super.key});

  @override
  State<MonitorPage> createState() => _MonitorPageState();
}

class _MonitorPageState extends State<MonitorPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final monitor = Provider.of<MonitoringService>(context, listen: false);
      if (!monitor.isMonitoring) {
        monitor.startMonitoring();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitoringService>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("RakshAI Live Monitor", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMonitoringStatus(monitor),

            const SizedBox(height: 20),

            _sensorDetailCard(
              title: "Voice Recognition",
              subtitle: monitor.isMonitoring ? "Listening for keywords..." : "Microphone Off",
              icon: Icons.mic,
              color: Colors.blue,
              isActive: monitor.isMonitoring,
            ),

            const SizedBox(height: 15),

            _sensorDetailCard(
              title: "Fall Detection",
              subtitle: monitor.isMonitoring ? "G-Force Monitor Active" : "Sensors Idle",
              icon: Icons.shutter_speed,
              color: Colors.orange,
              isActive: monitor.isMonitoring,
            ),

            const SizedBox(height: 15),

            _sensorDetailCard(
              title: "Live GPS Data",
              subtitle: "Lat: ${monitor.currentLatitude.toStringAsFixed(4)}\nLong: ${monitor.currentLongitude.toStringAsFixed(4)}",
              icon: Icons.location_on,
              color: Colors.green,
              isActive: true,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => monitor.isMonitoring ? monitor.stopMonitoring() : monitor.startMonitoring(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: monitor.isMonitoring ? Colors.red[400] : Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: Text(
                  monitor.isMonitoring ? "STOP RakshAI SENSORS" : "START RakshAI PROTECTION",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMonitoringStatus(MonitoringService monitor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: monitor.isMonitoring ? Colors.green : Colors.grey[400],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.security, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monitor.isMonitoring ? "System Protected" : "System Vulnerable",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  monitor.isMonitoring
                      ? "RakshAI Monitoring is active in background"
                      : "Sensors are off. Tap button to start.",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _sensorDetailCard({required String title, required String subtitle, required IconData icon, required Color color, required bool isActive}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(
          isActive ? Icons.check_circle : Icons.pause_circle_filled,
          color: isActive ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}