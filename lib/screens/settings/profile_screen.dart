import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _loadingAddress = "";

  final _restaurantController = TextEditingController();
  final _addressController = TextEditingController();
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await ApiService.get("accounts/profile/");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _restaurantController.text = data["restaurant_name"] ?? "";
          _addressController.text = data["address"] ?? "";
          if (data["latitude"] != null && data["longitude"] != null) {
            _currentPosition = LatLng(
              double.tryParse(data["latitude"].toString()) ?? 7.0731,
              double.tryParse(data["longitude"].toString()) ?? 125.6128,
            );
          } else {
            _currentPosition = LatLng(7.0731, 125.6128); // Default Davao City
          }
        });
      } else {
        _error = "Failed to load profile (${response.statusCode})";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  // ============================================================
  // 📍 Use Current Location
  // ============================================================
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });

    await _reverseGeocode(pos.latitude, pos.longitude);
  }

  // ============================================================
  // 🌍 Reverse Geocode (OpenStreetMap API)
  // ============================================================
  Future<void> _reverseGeocode(double lat, double lon) async {
    setState(() => _loadingAddress = "Fetching address...");
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon');
      final response =
          await http.get(url, headers: {'User-Agent': 'DARWCOS/1.0'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? 'Unknown location';
        setState(() {
          _addressController.text = address;
          _loadingAddress = "";
        });
      } else {
        throw Exception('Reverse geocoding failed');
      }
    } catch (e) {
      setState(() {
        _addressController.text =
            'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lon.toStringAsFixed(5)}';
        _loadingAddress = "";
      });
    }
  }

  // ============================================================
  // 💾 Save Profile
  // ============================================================
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location first")),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final body = {
      "restaurant_name": _restaurantController.text,
      "address": _addressController.text,
      "latitude": _currentPosition!.latitude,
      "longitude": _currentPosition!.longitude,
    };

    try {
      final response = await ApiService.patch("accounts/profile/", body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile updated successfully")),
        );
      } else {
        setState(() => _error = "Update failed: ${response.body}");
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  // ============================================================
  // 🧱 UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF015704);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Settings"),
        backgroundColor: green,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),

                    // 🧾 Restaurant Info
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Restaurant Info",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87)),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _restaurantController,
                              decoration: const InputDecoration(
                                labelText: "Restaurant Name",
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? "Enter restaurant name"
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            TextFormField(
                              controller: _addressController,
                              readOnly: true,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: "Address (Auto-filled)",
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.my_location,
                                      color: green),
                                  onPressed: _getCurrentLocation,
                                  tooltip: "Use Current Location",
                                ),
                              ),
                            ),
                            if (_loadingAddress.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, bottom: 4),
                                child: Text(_loadingAddress,
                                    style:
                                        const TextStyle(color: Colors.grey)),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 🗺️ Map
                    if (_currentPosition != null)
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: SizedBox(
                          height: 250,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: _currentPosition!,
                                initialZoom: 15,
                                onTap: (tapPos, point) {
                                  setState(() => _currentPosition = point);
                                  _reverseGeocode(
                                      point.latitude, point.longitude);
                                },
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.restaurant_frontend',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _currentPosition!,
                                      width: 40,
                                      height: 40,
                                      child: const Icon(Icons.location_on,
                                          color: Colors.red, size: 36),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // 💾 Save Button
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(
                        _saving ? "Saving..." : "Save Changes",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
