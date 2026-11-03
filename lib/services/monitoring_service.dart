import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:geocoding/geocoding.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:torch_light/torch_light.dart';

const String kEmergencyContactKey = 'emergency_contact';
const String kEmergencyEmailKey = 'emergency_email';

class MonitoringService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final Telephony telephony = Telephony.instance;
  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _speech = SpeechToText();
  final Battery _battery = Battery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isMonitoring = false;
  bool alertActive = false;
  String alertType = "NONE";
  int timerCount = 30;
  int userSetDuration = 30;
  bool movementDetectedAfterAlert = false;

  double currentLatitude = 0.0;
  double currentLongitude = 0.0;
  String riskLevel = "Calculating...";

  String currentAreaName = "Locating...";
  double accidentRate = 0.0;
  double harassmentRate = 0.0;

  bool isSirenActive = false;
  bool isFakeCallActive = false;
  bool isCallAnswered = false;
  Timer? _fakeCallTimer;
  int fakeCallCountdown = 0;

  bool batterySentinel = false;
  bool fakeDisguiseMode = false;
  int checkInSeconds = 0;
  Timer? _checkInTimer;

  List<String> sosKeywords = ["help", "police", "emergency", "danger"];
  List<String> contactNumbers = [];
  List<Map<String, String>> incidentLogs = [];

  double screamThreshold = 18.0;
  Timer? _sosTimer;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription<BatteryState>? _batterySubscription;

  StreamSubscription? _incomingRequestSub;

  MonitoringService() {
    _initLiveLocationTracking();
    _initBatteryListener();
    startPermissionListener();
  }




  void startPermissionListener() async {
    final prefs = await SharedPreferences.getInstance();
    final myPhone = prefs.getString('user_phone');

    if (myPhone == null) return;

    _incomingRequestSub = _supabase
        .from('location_permissions')
        .stream(primaryKey: ['id'])
        .eq('target_phone', myPhone)
        .listen((data) {
      final pendingRequests = data.where((req) => req['status'] == 'pending').toList();

      if (pendingRequests.isNotEmpty) {
        debugPrint(" New tracking request received from: ${pendingRequests.first['requester_phone']}");
        notifyListeners();
      }
    });
  }

  Future<void> updateMyLocationOnce() async {
    final prefs = await SharedPreferences.getInstance();
    final String myPhone = prefs.getString('user_phone') ?? "";

    if (myPhone.isEmpty) return;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      String mapsLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";

      await _supabase
          .from('location_permissions')
          .update({
        'live_link': mapsLink,
        'last_seen': DateTime.now().toIso8601String(),
      })
          .eq('target_phone', myPhone)
          .eq('status', 'approved');

      currentLatitude = position.latitude;
      currentLongitude = position.longitude;

      notifyListeners();
      debugPrint(" Location manually synced for $myPhone");
    } catch (e) {
      debugPrint(" Manual Sync Error: $e");
    }
  }

  Future<void> requestFamilyTracking(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    String myPhone = prefs.getString('user_phone') ?? "";
    String myEmail = prefs.getString('user_email') ?? "A family member";

    final myUid = _supabase.auth.currentUser?.id;

    if (myPhone.isEmpty || myUid == null) {
      debugPrint(" Error: Missing Phone or User UUID");
      return;
    }

    try {
      await _supabase.from('location_permissions').insert({
        'requester_id': myUid,
        'requester_phone': myPhone,
        'target_phone': phoneNumber.trim(),
        'status': 'pending',
        'is_tracking_on': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      String msg = "SECURITY: $myEmail wants to track your live location for safety. Open RakshAI to approve/deny.";
      await _sendSmsAutomatically(phoneNumber, msg);
      notifyListeners();
    } catch (e) {
      debugPrint("Tracking Request Error: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getTrackedFamilyStream(String myUserPhone) {
    if (myUserPhone.isEmpty) return const Stream.empty();

    return _supabase
        .from('location_permissions')
        .stream(primaryKey: ['id'])
        .eq('requester_phone', myUserPhone);
  }

  Stream<List<Map<String, dynamic>>> getIncomingRequestsStream(String myPhone) {
    if (myPhone.isEmpty) return const Stream.empty();

    return _supabase
        .from('location_permissions')
        .stream(primaryKey: ['id'])
        .eq('target_phone', myPhone)
        .map((list) {
      final filtered = list.where((item) => item['status'] == 'pending').toList();
      filtered.sort((a, b) => b['id'].compareTo(a['id']));
      return filtered;
    });
  }

  Future<void> respondToRequest(int id, bool approve) async {
    try {
      await _supabase.from('location_permissions').update({
        'status': approve ? 'approved' : 'denied',
        'is_tracking_on': approve,
      }).eq('id', id);

      final myUid = _supabase.auth.currentUser?.id;
      if (approve && myUid != null) {
        await _supabase.from('location_permissions').update({
          'target_id': myUid,
        }).eq('id', id);
      }

      notifyListeners();
      debugPrint(" Request ${approve ? 'Approved' : 'Denied'} for ID: $id");
    } catch (e) {
      debugPrint(" Error responding to request: $e");
    }
  }

  Future<void> stopTracking(int connectionId) async {
    await _supabase.from('location_permissions').update({
      'is_tracking_on': false,
      'status': 'revoked'
    }).eq('id', connectionId);
    notifyListeners();
  }


  void toggleSiren() async {
    isSirenActive = !isSirenActive;
    notifyListeners();

    if (isSirenActive) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/siren.mp3'));
      _runStrobeLoop();
    } else {
      await _audioPlayer.stop();
      try { await TorchLight.disableTorch(); } catch (_) {}
    }
  }

  void _runStrobeLoop() async {
    while (isSirenActive) {
      try {
        await TorchLight.enableTorch();
        await Future.delayed(const Duration(milliseconds: 150));
        await TorchLight.disableTorch();
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (e) { break; }
    }
  }


  void triggerFakeCall() {
    isFakeCallActive = true;
    isCallAnswered = false;
    notifyListeners();
  }

  void answerFakeCall() async {
    isCallAnswered = true;
    notifyListeners();
  }

  void endFakeCall() {
    isFakeCallActive = false;
    isCallAnswered = false;
    _audioPlayer.stop();
    notifyListeners();
  }

  void scheduleFakeCall(int seconds) {
    _fakeCallTimer?.cancel();
    fakeCallCountdown = seconds;
    notifyListeners();

    _fakeCallTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (fakeCallCountdown > 0) {
        fakeCallCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
        triggerFakeCall();
      }
    });
  }

  void cancelScheduledCall() {
    _fakeCallTimer?.cancel();
    fakeCallCountdown = 0;
    notifyListeners();
  }


  Future<void> _sendSmsAutomatically(String number, String message) async {
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    bool? permissionsGranted = await telephony.requestSmsPermissions;

    if (permissionsGranted == true) {
      try {
        await telephony.sendSms(
          to: cleanNumber,
          message: message,
          statusListener: (SendStatus status) {
            if (status != SendStatus.SENT && status != SendStatus.DELIVERED) {
              _sendSmsManual(cleanNumber, message);
            }
          },
        );
      } catch (e) { _sendSmsManual(cleanNumber, message); }
    } else { await _sendSmsManual(cleanNumber, message); }
  }

  Future<void> _sendEmailWithAttachment(String filePath, String recipientEmail) async {
    String senderEmail = '****';
    String appPassword = '**** **** **** ****';
    final smtpServer = gmail(senderEmail, appPassword);
    String mapsLink = "https://www.google.com/maps/search/?api=1&query=$currentLatitude,$currentLongitude";

    final message = Message()
      ..from = Address(senderEmail, 'SOS Safety System')
      ..recipients.add(recipientEmail)
      ..subject = 'EMERGENCY VOICE RECORDING: ${DateTime.now()}'
      ..text = 'SOS Alert Triggered.\nReason: $alertType\nLive Location: $mapsLink'
      ..attachments.add(FileAttachment(File(filePath)));

    try { await send(message, smtpServer); } catch (e) { debugPrint(" Email failed: $e"); }
  }

  void _executeEmergencyProtocol({required bool isDeadMan, required String reason}) async {
    alertActive = true;
    notifyListeners();
    WakelockPlus.enable();

    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedContact = prefs.getString(kEmergencyContactKey) ??
          (contactNumbers.isNotEmpty ? contactNumbers.first : null);

      if (savedContact == null || savedContact.isEmpty) return;

      final cleanNumber = savedContact.replaceAll(RegExp(r'[^\d+]'), '');
      String mapsLink = "https://www.google.com/maps/search/?api=1&query=$currentLatitude,$currentLongitude";
      String firstMsg = "Distress Alert!\nReason: $reason\nLive Location: $mapsLink";

      await _sendSmsAutomatically(cleanNumber, firstMsg);
      await Future.delayed(const Duration(seconds: 3));

      final Uri callUri = Uri.parse("tel:$cleanNumber");
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
      }
      await _handleEmergencyRecording();
    } catch (e) { debugPrint("Protocol Error: $e"); }
    finally {
      WakelockPlus.disable();
      alertActive = false;
      notifyListeners();
    }
  }

  Future<void> _handleEmergencyRecording() async {
    final prefs = await SharedPreferences.getInstance();
    int recordDuration = prefs.getInt('recording_duration') ?? 30;

    if (await _recorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/sos_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(const RecordConfig(), path: path);
      await Future.delayed(Duration(seconds: recordDuration));

      final finalPath = await _recorder.stop();
      if (finalPath != null) {
        String? savedEmail = prefs.getString(kEmergencyEmailKey);
        String? savedContact = prefs.getString(kEmergencyContactKey) ?? (contactNumbers.isNotEmpty ? contactNumbers.first : null);

        if (savedEmail != null && savedEmail.isNotEmpty) await _sendEmailWithAttachment(finalPath, savedEmail);
        if (prefs.getBool('upload_enabled') ?? true) {
          if (savedContact != null) await _processAndSendEvidenceToContact(finalPath, savedContact.replaceAll(RegExp(r'[^\d+]'), ''));
        }
      }
    }
  }

  Future<bool> _processAndSendEvidenceToContact(String localPath, String contact) async {
    final fileName = "SOS_EVIDENCE_${DateTime.now().millisecondsSinceEpoch}.m4a";
    try {
      File fileToUpload = File(localPath);
      await _supabase.storage.from('emergency_audio').upload(fileName, fileToUpload);
      final publicUrl = _supabase.storage.from('emergency_audio').getPublicUrl(fileName);
      await Future.delayed(const Duration(seconds: 2));
      await _sendSmsAutomatically(contact, "Audio Evidence:\n$publicUrl");
      return true;
    } catch (e) { return false; }
  }


  void _initLiveLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 10),
    ).listen((Position position) {
      currentLatitude = position.latitude;
      currentLongitude = position.longitude;

      _syncLiveLinkToSupabase();

      _performLiveRiskAnalysis();
      notifyListeners();
    });
  }

  Future<void> _syncLiveLinkToSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    final String myPhone = prefs.getString('user_phone') ?? "";

    if (myPhone.isEmpty || currentLatitude == 0.0) return;

    String mapsLink = "https://www.google.com/maps/search/?api=1&query=$currentLatitude,$currentLongitude";

    try {
      await _supabase
          .from('location_permissions')
          .update({
        'live_link': mapsLink,
        'last_seen': DateTime.now().toIso8601String(),
      })
          .eq('target_phone', myPhone)
          .eq('status', 'approved')
          .eq('is_tracking_on', true);
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  void _performLiveRiskAnalysis() async {
    if (currentLatitude == 0.0) return;
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(currentLatitude, currentLongitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentAreaName = "${place.locality ?? "Unknown"}, ${place.administrativeArea ?? ""}";
      }
      double dist = sqrt(pow(currentLatitude - 21.0, 2) + pow(currentLongitude - 72.0, 2));
      riskLevel = dist > 0.5 ? "Safe Area" : "High Risk Zone";
      _updateAreaSafetyStats(dist);
      notifyListeners();
    } catch (e) { debugPrint("Geocoding Error: $e"); }
  }

  void _updateAreaSafetyStats(double distance) {
    if (distance <= 0.5) {
      accidentRate = 4.2 + (Random().nextDouble() * 2);
      harassmentRate = 1.8 + (Random().nextDouble() * 1);
    } else {
      accidentRate = 0.5 + (Random().nextDouble() * 1);
      harassmentRate = 0.1 + (Random().nextDouble() * 0.3);
    }
  }

  void _startSpeechEngine() {
    if (!_speech.isAvailable || _speech.isListening) return;

    _speech.listen(
      onResult: (result) {
        String heard = result.recognizedWords.toLowerCase();
        for (var word in sosKeywords) {
          if (heard.contains(word)) {
            _triggerSOS("VOICE DISTRESS ($word)");
            break;
          }
        }
      },
      onSoundLevelChange: (level) {
        if (level > screamThreshold && !alertActive) {
          _triggerSOS("PANIC NOISE / SCREAM");
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
      listenMode: ListenMode.deviceDefault,
    );
  }

  void startMonitoring() async {
    isMonitoring = true;
    notifyListeners();
    bool speechAvailable = await _speech.initialize(onStatus: (status) {
      if ((status == 'done' || status == 'notListening') && isMonitoring) _startSpeechEngine();
    });
    if (speechAvailable) _startSpeechEngine();
    _accelerometerSubscription = userAccelerometerEvents.listen((event) {
      if (sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2)) > 25) _triggerSOS("FALL DETECTED");
    });
  }

  void _triggerSOS(String type) {
    if (alertActive) return;
    alertActive = true;
    alertType = type;
    timerCount = userSetDuration;
    movementDetectedAfterAlert = false;
    _recordIncident(type);
    _startDeadManMovementCheck();
    notifyListeners();
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerCount > 0) {
        timerCount--;
        notifyListeners();
      } else {
        timer.cancel();
        _handleDeadManEscalation();
      }
    });
  }

  void _startDeadManMovementCheck() {
    StreamSubscription? tempSub;
    tempSub = userAccelerometerEvents.listen((event) {
      if (sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2)) > 1.5) {
        movementDetectedAfterAlert = true;
        tempSub?.cancel();
      }
    });
  }

  void _initBatteryListener() {
    _batterySubscription = _battery.onBatteryStateChanged.listen((state) async {
      if (batterySentinel) {
        int level = await _battery.batteryLevel;
        if (level <= 5) _executeEmergencyProtocol(isDeadMan: false, reason: "LOW BATTERY");
      }
    });
  }

  void _handleDeadManEscalation() => _executeEmergencyProtocol(isDeadMan: !movementDetectedAfterAlert, reason: alertType);
  void _executeFinalSOS() => _executeEmergencyProtocol(isDeadMan: true, reason: "CHECK-IN TIMEOUT");

  void toggleBatterySentinel(bool val) { batterySentinel = val; notifyListeners(); }
  void toggleFakeDisguise(bool val) { fakeDisguiseMode = val; notifyListeners(); }

  void updateUserDuration(int newDuration) {
    userSetDuration = newDuration;
    notifyListeners();
  }

  void addCustomWord(String word) {
    if (word.isNotEmpty && !sosKeywords.contains(word.toLowerCase())) {
      sosKeywords.add(word.toLowerCase().trim());
      notifyListeners();
    }
  }

  void removeCustomWord(String word) {
    sosKeywords.remove(word);
    notifyListeners();
  }

  void startCheckInTimer(int minutes) {
    checkInSeconds = minutes * 60;
    _checkInTimer?.cancel();
    _checkInTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (checkInSeconds > 0) { checkInSeconds--; notifyListeners(); }
      else { timer.cancel(); _executeFinalSOS(); }
    });
  }

  void cancelCheckIn() { _checkInTimer?.cancel(); checkInSeconds = 0; notifyListeners(); }
  void updateScreamThreshold(double newValue) { screamThreshold = newValue; notifyListeners(); }
  void addContact(String number) { contactNumbers.add(number.trim()); notifyListeners(); }
  void removeContact(String number) { contactNumbers.remove(number); notifyListeners(); }

  Future<void> _sendSmsManual(String number, String message) async {
    final Uri smsUri = Uri(scheme: 'sms', path: number, queryParameters: <String, String>{'body': message});
    if (await canLaunchUrl(smsUri)) await launchUrl(smsUri);
  }

  void _recordIncident(String type) {
    incidentLogs.insert(0, {"type": type, "date": DateTime.now().toString(), "location": "$currentLatitude, $currentLongitude"});
  }

  void cancelAlert() { alertActive = false; _sosTimer?.cancel(); notifyListeners(); }
  void stopMonitoring() { isMonitoring = false; _speech.stop(); _accelerometerSubscription?.cancel(); cancelAlert(); notifyListeners(); }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _sosTimer?.cancel();
    _checkInTimer?.cancel();
    _fakeCallTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _batterySubscription?.cancel();
    _incomingRequestSub?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}