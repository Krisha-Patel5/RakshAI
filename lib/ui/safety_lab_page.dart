import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/monitoring_service.dart';

class SafetyLabPage extends StatelessWidget {
  const SafetyLabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitoringService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Safety Power Lab", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader("PROACTIVE PROTECTION"),

          _buildLabCard(
            title: "Check-In Timer",
            subtitle: monitor.checkInSeconds > 0
                ? "Triggering SOS in ${monitor.checkInSeconds ~/ 60}m ${monitor.checkInSeconds % 60}s"
                : "Alert if you don't check in by a certain time.",
            icon: Icons.timer_outlined,
            color: Colors.deepPurple,
            trailing: monitor.checkInSeconds > 0
                ? TextButton(
                onPressed: () => monitor.cancelCheckIn(),
                child: const Text("STOP", style: TextStyle(color: Colors.red))
            )
                : ElevatedButton(
              onPressed: () => _showTimerPicker(context, monitor),
              child: const Text("SET"),
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader("STEALTH & SURVIVAL"),

          _buildSwitchCard(
            title: "Disguise Mode",
            subtitle: "Triple-tap AI status to show a fake Weather App.",
            icon: Icons.vpn_lock,
            value: monitor.fakeDisguiseMode,
            onChanged: (val) => monitor.toggleFakeDisguise(val), // 👈 Integrated method
          ),

          _buildSwitchCard(
            title: "Battery Sentinel",
            subtitle: "Send last location automatically at 5% battery.",
            icon: Icons.battery_alert,
            value: monitor.batterySentinel,
            onChanged: (val) => monitor.toggleBatterySentinel(val), // 👈 Integrated method
          ),

          const SizedBox(height: 20),
          _buildSectionHeader("SYSTEM SETTINGS"),

          // 4. Foreground Service
          _buildLabCard(
            title: "Background Persistence",
            subtitle: "Keep AI alive even when the phone is locked.",
            icon: Icons.run_circle_outlined,
            color: Colors.blue,
            trailing: Switch(
              value: true,
              onChanged: (v) {
              },
              activeColor: Colors.blue,
            ),
          ),

          const SizedBox(height: 30),
          const Center(
            child: Text("v2.0.4 - Real World Ready",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }

  void _showTimerPicker(BuildContext context, MonitoringService monitor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 250,
        child: Column(
          children: [
            const Text("Walk Home Timer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [5, 15, 30, 60].map((mins) => ActionChip(
                label: Text("$mins min"),
                onPressed: () {
                  monitor.startCheckInTimer(mins);
                  Navigator.pop(context);
                },
              )).toList(),
            ),
            const SizedBox(height: 20),
            const Text("If you don't cancel this timer, an SOS will be sent automatically.",
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1)),
    );
  }

  Widget _buildLabCard({required String title, required String subtitle, required IconData icon, required Color color, required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSwitchCard({required String title, required String subtitle, required IconData icon, required bool value, required Function(bool) onChanged}) {
    return _buildLabCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: Colors.orange,
      trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.orange
      ),
    );
  }
}