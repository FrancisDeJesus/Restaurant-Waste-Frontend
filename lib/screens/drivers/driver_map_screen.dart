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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // speed of line animation
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _initLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🛰 Get driver’s current location
  Future<void> _initLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied.")),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() => _driverPos = LatLng(pos.latitude, pos.longitude));

    _fetchRoute();
  }

  // 📡 Fetch driving route from OSRM API
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

        // Start animation
        _controller.reset();
        _controller.forward();

        // Gradually reveal the route points
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
      }
    } catch (e) {
      debugPrint("⚠️ Route fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupPos = LatLng(widget.pickupLat, widget.pickupLng);

    return Scaffold(
      appBar: AppBar(title: const Text("Pickup Route")),
      body: _driverPos == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _driverPos!,
                initialZoom: 13,
              ),
              children: [
                // 🗺 Base map
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
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.circle,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    Marker(
                      point: pickupPos,
                      width: 80,
                      height: 80,
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
        onPressed: _fetchRoute,
        tooltip: "Refresh Route",
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
