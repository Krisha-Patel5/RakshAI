import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/monitoring_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // 📞 Direct Call Function
  void _makeCall(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitoringService>();

    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar hides automatically during a Fake Call
      appBar: monitor.isFakeCallActive
          ? null
          : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "RakshAI",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.biotech, color: Colors.blue),
            tooltip: "Safety Lab",
            onPressed: () => Navigator.pushNamed(context, '/lab'),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            tooltip: "Settings",
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [

          SingleChildScrollView(
            child: Column(
              children: [
                _buildAreaInsights(monitor),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Quick Disguise",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),


                      if (monitor.fakeCallCountdown > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Fake Call in ${monitor.fakeCallCountdown}s",
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: () => monitor.cancelScheduledCall(),
                                child: const Icon(Icons.cancel, color: Colors.blue, size: 20),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        children: [
                          _toolkitCard("Fake Call", Icons.phone_callback, Colors.blue,
                              monitor.triggerFakeCall),
                          const SizedBox(width: 12),
                          _toolkitCard(
                              monitor.isSirenActive ? "Stop Siren" : "Siren Blast",
                              Icons.campaign,
                              monitor.isSirenActive ? Colors.red : Colors.orange,
                              monitor.toggleSiren,
                              isActive: monitor.isSirenActive
                          ),
                          const SizedBox(width: 12),
                          _toolkitCard(
                              "Schedule (2m)",
                              Icons.timer,
                              Colors.purple,
                                  () => monitor.scheduleFakeCall(120)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                Container(
                  margin: const EdgeInsets.symmetric(vertical: 15),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: monitor.isMonitoring ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: monitor.isMonitoring ? Colors.green : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        monitor.isMonitoring ? "AI SENSORS ACTIVE" : "AI SENSORS IDLE",
                        style: TextStyle(
                          color: monitor.isMonitoring ? Colors.green[700] : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                monitor.alertActive
                    ? _buildCountdownUI(monitor)
                    : _buildSOSButton(monitor),

                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quick Services",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.3,
                        children: [
                          _serviceCard("Police", Icons.shield, Colors.blue, "100"),
                          _serviceCard("Ambulance", Icons.medical_services, Colors.red, "102"),
                          _serviceCard("Fire", Icons.fire_truck, Colors.orange, "101"),
                          _serviceCard("Emergency", Icons.phone, Colors.green, "112"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          if (monitor.isFakeCallActive) _buildFakeCallOverlay(monitor),
        ],
      ),
    );
  }


  Widget _toolkitCard(String title, IconData icon, Color color, VoidCallback onTap, {bool isActive = false}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isActive ? Colors.white : color, size: 24),
              const SizedBox(height: 6),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFakeCallOverlay(MonitoringService monitor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1C1C1E), // Deep black background
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text("Incoming Call", style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Mom / Home", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w400)),
            const Spacer(),

            if (!monitor.isCallAnswered) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _callCircleButton(Icons.call_end, "Decline", Colors.red, monitor.endFakeCall),
                  _callCircleButton(Icons.call, "Accept", Colors.green, monitor.answerFakeCall),
                ],
              )
            ] else ...[
              const Text("00:04", style: TextStyle(color: Colors.white, fontSize: 18)),
              const Spacer(),
              _callCircleButton(Icons.call_end, "End", Colors.red, monitor.endFakeCall),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _callCircleButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 75, height: 75,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildAreaInsights(MonitoringService monitor) {
    bool isHighRisk = monitor.riskLevel.contains("High");
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighRisk ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isHighRisk ? Colors.red.withOpacity(0.2) : Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CURRENT AREA", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    Text(monitor.currentAreaName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isHighRisk ? Colors.red : Colors.green, shape: BoxShape.circle), child: Icon(isHighRisk ? Icons.warning_rounded : Icons.check_circle, color: Colors.white, size: 28))
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dataPoint("STATUS", monitor.riskLevel, isHighRisk ? Colors.red : Colors.green),
              _dataPoint("ACCIDENTS", "${monitor.accidentRate.toStringAsFixed(1)}%", Colors.orange),
              _dataPoint("HARASSMENT", "${monitor.harassmentRate.toStringAsFixed(1)}%", Colors.purple),
            ],
          )
        ],
      ),
    );
  }

  Widget _dataPoint(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _serviceCard(String title, IconData icon, Color color, String number) {
    return InkWell(
      onTap: () => _makeCall(number),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(MonitoringService monitor) {
    return GestureDetector(
      onLongPress: () => monitor.startMonitoring(),
      child: Column(
        children: [
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red, boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 40, spreadRadius: 5)]),
            child: const Center(child: Text("SOS", style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold, letterSpacing: 2))),
          ),
          const SizedBox(height: 15),
          const Text("HOLD TO ACTIVATE AI PROTECTION", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCountdownUI(MonitoringService monitor) {
    return Column(
      children: [
        Container(
          width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 6)),
          child: Center(child: Text("${monitor.timerCount}", style: const TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: Colors.red))),
        ),
        const SizedBox(height: 15),
        Text("${monitor.alertType}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: () => monitor.cancelAlert(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 30), shape: const StadiumBorder()),
          child: const Text("CANCEL ALERT"),
        ),
      ],
    );
  }
}