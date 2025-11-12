// lib/screens/drivers/driver_map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class DriverMapScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String address;

  const DriverMapScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.address,
  });

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen>
    with SingleTickerProviderStateMixin {
  LatLng? _driverPos;
  List<LatLng> _routePoints = [];
  List<LatLng> _visiblePoints = [];

  late AnimationController _controller;
  late Animation<double> _animation;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _initLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🛰 Request location permission + current position
  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = "Location services are disabled. Please enable GPS.";
          _loading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = "Location permission denied.";
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _driverPos = LatLng(pos.latitude, pos.longitude);
        _loading = false;
      });

      _fetchRoute();
    } catch (e) {
      setState(() {
        _error = "Error fetching location: $e";
        _loading = false;
      });
    }
  }

  // 🚗 Fetch route from OSRM API
  Future<void> _fetchRoute() async {
    if (_driverPos == null) return;

    final start = "${_driverPos!.longitude},${_driverPos!.latitude}";
    final end = "${widget.pickupLng},${widget.pickupLat}";
    final url =
        "https://router.project-osrm.org/route/v1/driving/$start;$end?overview=full&geometries=geojson";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final coords = data["routes"][0]["geometry"]["coordinates"] as List;

        _routePoints = coords
            .map((c) => LatLng(c[1].toDouble(), c[0].toDouble()))
            .toList();

        _controller.reset();
        _controller.forward();

        _controller.addListener(() {
          final portion = (_controller.value * _routePoints.length).toInt();
          if (portion > 0 && portion <= _routePoints.length) {
            setState(() {
              _visiblePoints = _routePoints.sublist(0, portion);
            });
          }
        });
      } else {
        debugPrint("⚠️ Route API failed: ${res.statusCode}");
        setState(() => _error = "Route service unavailable.");
      }
    } catch (e) {
      debugPrint("⚠️ Route fetch error: $e");
      setState(() => _error = "Network error while fetching route.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupPos = LatLng(widget.pickupLat, widget.pickupLng);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Pickup Route",
          style: TextStyle(color: Color(0xFF015704), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF015704)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF015704)))
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : _driverPos == null
                  ? const Center(child: Text("Unable to fetch location."))
                  : FlutterMap(
                      options: MapOptions(
                        initialCenter: _driverPos!,
                        initialZoom: 13,
                      ),
                      children: [
                        // 🗺️ Map layer
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c'],
                        ),

                        // 🔵 Animated route
                        if (_visiblePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _visiblePoints,
                                color: Colors.blueAccent,
                                strokeWidth: 5.0,
                              ),
                            ],
                          ),

                        // 📍 Markers
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _driverPos!,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.directions_car_rounded,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                            Marker(
                              point: pickupPos,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF015704),
        onPressed: _fetchRoute,
        tooltip: "Refresh Route",
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
