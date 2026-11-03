import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/monitoring_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _keywordController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;

  bool _uploadEnabled = true;
  double _recordingSeconds = 30.0;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController();
    _contactController = TextEditingController();
    _emailController = TextEditingController();
    _loadStoredSettings(); // Load the Cloud/Timer settings on startup
  }

  Future<void> _loadStoredSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uploadEnabled = prefs.getBool('upload_enabled') ?? true;
      _recordingSeconds = prefs.getDouble('recording_seconds') ?? 30.0;

      // Load existing contact into the controller if it exists
      String? savedNumber = prefs.getString(kEmergencyContactKey);
      if (savedNumber != null) {
        _contactController.text = savedNumber;
      }

      // 3. Load stored email into the controller
      String? savedEmail = prefs.getString(kEmergencyEmailKey);
      if (savedEmail != null) {
        _emailController.text = savedEmail;
      }
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('upload_enabled', _uploadEnabled);
    await prefs.setDouble('recording_seconds', _recordingSeconds);
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _contactController.dispose();
    // Dispose Email Controller
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitoringService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("App Settings",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text("Cloud Storage & Evidence",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.cloud_upload, color: _uploadEnabled ? Colors.blue : Colors.grey),
              title: const Text("Store Audio Evidence"),
              subtitle: const Text("Uploads recording to secure cloud after SOS"),
              value: _uploadEnabled,
              onChanged: (bool value) {
                setState(() => _uploadEnabled = value);
                _saveSettings();
              },
            ),

            const Divider(height: 40),

            const Text("Emergency Email",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("The audio recording file will be sent here automatically.",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Enter Emergency Email",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save, color: Colors.blue),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(kEmergencyEmailKey, _emailController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Emergency Email Saved")),
                      );
                    }
                  },
                ),
              ),
            ),

            const Divider(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Evidence Recording Time",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${_recordingSeconds.round()}s",
                    style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            const Text("How long the app records audio after an SOS is triggered.",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            Slider(
              value: _recordingSeconds,
              min: 10,
              max: 120,
              divisions: 11,
              activeColor: Colors.green,
              label: "${_recordingSeconds.round()} seconds",
              onChanged: (double value) {
                setState(() => _recordingSeconds = value);
                _saveSettings();
              },
            ),

            const Divider(height: 40),

            const Text("Emergency Contacts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Enter Phone Number",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 35),
                  onPressed: () async {
                    if (_contactController.text.isNotEmpty) {
                      monitor.addContact(_contactController.text);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(kEmergencyContactKey, _contactController.text);
                      _contactController.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Emergency Contact Saved Permanently")),
                        );
                      }
                    }
                  },
                ),
              ],
            ),

            if (monitor.contactNumbers.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: monitor.contactNumbers.length,
                itemBuilder: (context, index) {
                  final number = monitor.contactNumbers[index];
                  return Card(
                    color: Colors.grey[50],
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.blue),
                      title: Text(number,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => monitor.removeContact(number),
                      ),
                    ),
                  );
                },
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text("No contacts added yet.",
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ),

            const Divider(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("SOS Countdown Delay",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${monitor.userSetDuration}s",
                    style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            Slider(
              value: monitor.userSetDuration.toDouble(),
              min: 5,
              max: 60,
              divisions: 11,
              activeColor: Colors.red,
              onChanged: (double value) {
                monitor.updateUserDuration(value.toInt());
              },
            ),

            const Divider(height: 40),

            const Text("Custom Voice Triggers",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: monitor.sosKeywords
                  .map((word) => Chip(
                backgroundColor: Colors.purple[50],
                label: Text(word,
                    style: const TextStyle(color: Colors.purple)),
                onDeleted: () => monitor.removeCustomWord(word),
                deleteIconColor: Colors.purple,
              ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _keywordController,
              decoration: InputDecoration(
                hintText: "Add word (e.g., 'Danger')",
                filled: true,
                fillColor: Colors.grey[100],
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.purple),
                  onPressed: () {
                    if (_keywordController.text.isNotEmpty) {
                      monitor.addCustomWord(_keywordController.text);
                      _keywordController.clear();
                    }
                  },
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),

            const Divider(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Scream Sensitivity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(monitor.screamThreshold.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 5),
            const Text("Triggers SOS if volume exceeds this level (useful for screams).",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            Slider(
              value: monitor.screamThreshold,
              min: 5.0,
              max: 30.0,
              divisions: 25,
              activeColor: Colors.orange,
              onChanged: (double value) {
                monitor.updateScreamThreshold(value);
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}