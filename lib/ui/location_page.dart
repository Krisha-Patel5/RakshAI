import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/monitoring_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  String _address = "Fetching address name...";
  GoogleMapController? _mapController;
  LatLng? _lastAddressUpdatePos;

  // Family Network Variables
  final TextEditingController _phoneController = TextEditingController();
  String myPhone = "";

  // Realtime Variables
  StreamSubscription? _permissionSubscription;
  List<Map<String, dynamic>> currentRequests = [];

  @override
  void initState() {
    super.initState();
    _setupPermissionListener();
  }

  void _setupPermissionListener() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone') ?? "";

    if (mounted) {
      setState(() {
        myPhone = phone;
      });
    }

    if (phone.isNotEmpty) {
      final supabase = Supabase.instance.client;

      _permissionSubscription = supabase
          .from('location_permissions')
          .stream(primaryKey: ['id'])
          .eq('target_phone', phone)
          .listen((List<Map<String, dynamic>> data) {

        final pending = data.where((d) => d['status'] == 'pending').toList();

        if (pending.isNotEmpty && mounted) {
          setState(() {
            currentRequests = pending;
          });
          _showApprovalDialog(pending.first);
        }
      });
    }
  }

  void _showApprovalDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 10),
            Text("Tracking Request"),
          ],
        ),
        content: Text(
          "A family member (${request['requester_phone']}) is requesting to track your live location for safety. Do you approve?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<MonitoringService>().respondToRequest(request['id'], false);
              Navigator.pop(context);
            },
            child: const Text("DENY", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              context.read<MonitoringService>().respondToRequest(request['id'], true);
              Navigator.pop(context);
            },
            child: const Text("APPROVE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAddressIfNeeded(double lat, double lng) async {
    if (lat == 0.0 || lng == 0.0) return;

    if (_lastAddressUpdatePos != null) {
      double distance = Geolocator.distanceBetween(
        _lastAddressUpdatePos!.latitude,
        _lastAddressUpdatePos!.longitude,
        lat,
        lng,
      );
      if (distance < 50) return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _lastAddressUpdatePos = LatLng(lat, lng);
            _address = "${place.name ?? ''} ${place.street ?? ''}, ${place.locality ?? ''}";
          });
        }
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  Future<void> _getDirections(String destinationType) async {
    final String query = Uri.encodeComponent(destinationType);
    final Uri googleMapsUrl = Uri.parse("google.navigation:q=$query");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      final Uri webUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
      await launchUrl(webUrl);
    }
  }

  @override
  void dispose() {
    _permissionSubscription?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitoringService>();
    final double lat = monitor.currentLatitude;
    final double lng = monitor.currentLongitude;
    final String risk = monitor.riskLevel;

    _updateAddressIfNeeded(lat, lng);

    final LatLng currentLatLng = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Safety Map"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (lat != 0.0 && lng != 0.0) {
                _mapController?.animateCamera(CameraUpdate.newLatLng(currentLatLng));
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: currentLatLng, zoom: 15),
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId("live_user"),
                        position: currentLatLng,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                      ),
                    },
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: risk.contains("High") ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text("STATUS: $risk", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("CURRENT ADDRESS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(_address, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),

                  const SizedBox(height: 20),

                  const Text("ADD FAMILY MEMBER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: "Enter Phone Number",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.person_add, color: Colors.blue),
                        onPressed: () {
                          if (_phoneController.text.isNotEmpty) {
                            monitor.requestFamilyTracking(_phoneController.text);
                            _phoneController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Sent!")));
                          }
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),

                  const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),

                  const Text("FAMILY SAFETY NETWORK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),

                  if (myPhone.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ))
                  else
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: monitor.getTrackedFamilyStream(myPhone),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text("Connection Error. Please check Realtime settings.",
                              style: TextStyle(color: Colors.red, fontSize: 12));
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }

                        final members = snapshot.data ?? [];
                        if (members.isEmpty) return const Text("No family members added.", style: TextStyle(color: Colors.grey, fontSize: 12));

                        return Column(
                          children: members.map((member) {
                            bool isApproved = member['status'] == 'approved';

                            String lastSeen = "Never";
                            if (member['last_seen'] != null) {
                              DateTime dt = DateTime.parse(member['last_seen']).toLocal();
                              lastSeen = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                                  child: Icon(
                                    isApproved ? Icons.location_on : Icons.access_time_filled,
                                    color: isApproved ? Colors.green : Colors.orange,
                                  ),
                                ),
                                title: Text(
                                  member['target_phone'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  isApproved ? "Last Updated: $lastSeen" : "Status: Pending Approval",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isApproved)
                                      IconButton(
                                        icon: const Icon(Icons.refresh, color: Colors.blue),
                                        tooltip: "Update Location",
                                        onPressed: () async {
                                          await monitor.updateMyLocationOnce();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text("Location Shared Successfully!"))
                                            );
                                          }
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => monitor.stopTracking(member['id']),
                                    ),
                                  ],
                                ),
                                onTap: isApproved && member['live_link'] != null
                                    ? () async {
                                  final url = Uri.parse(member['live_link']);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                }
                                    : null,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                  const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),

                  const Text("QUICK NAVIGATION", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _directionChip("Police", Icons.local_police, Colors.blue),
                        const SizedBox(width: 8),
                        _directionChip("Hospital", Icons.local_hospital, Colors.red),
                        const SizedBox(width: 8),
                        _directionChip("Pharmacy", Icons.medical_services, Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _directionChip(String label, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      onPressed: () => _getDirections(label),
      backgroundColor: color.withOpacity(0.05),
    );
  }
}