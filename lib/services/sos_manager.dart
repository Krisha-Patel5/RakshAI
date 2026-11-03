import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SOSManager extends ChangeNotifier {
  String _emergencyContact = "100";

  String get emergencyContact => _emergencyContact;

  SOSManager() {
    loadContact();
  }

  Future<void> loadContact() async {
    final prefs = await SharedPreferences.getInstance();
    _emergencyContact = prefs.getString('emergency_contact') ?? "100";
    notifyListeners();
  }

  Future<void> updateContact(String newNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_contact', newNumber);
    _emergencyContact = newNumber;
    notifyListeners();
  }

  Future<void> makeCall(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> sendSOS() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final String msg = "EMERGENCY! I need help. Location: https://www.google.com/maps?q=${pos.latitude},${pos.longitude}";
      final Uri uri = Uri.parse("sms:$_emergencyContact?body=${Uri.encodeComponent(msg)}");

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("SOS Error: $e");
    }
  }
}