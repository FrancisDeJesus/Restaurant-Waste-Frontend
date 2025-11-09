import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api/auth_api.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  LatLng _selectedLocation = LatLng(7.1907, 125.4553); // Davao City center
  String _loadingAddress = '';

  @override
  void dispose() {
    _restaurantController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // 🔹 Reverse-geocode coordinates → readable address
  Future<void> _reverseGeocode(LatLng location) async {
    setState(() => _loadingAddress = 'Fetching address...');
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${location.latitude}&lon=${location.longitude}');
      final response = await http.get(url, headers: {'User-Agent': 'FlutterApp/1.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? 'Unknown location';
        setState(() {
          _addressController.text = address;
          _loadingAddress = '';
        });
      } else {
        setState(() {
          _addressController.text =
              'Lat: ${location.latitude.toStringAsFixed(5)}, Lng: ${location.longitude.toStringAsFixed(5)}';
          _loadingAddress = '';
        });
      }
    } catch (_) {
      setState(() {
        _addressController.text =
            'Lat: ${location.latitude.toStringAsFixed(5)}, Lng: ${location.longitude.toStringAsFixed(5)}';
        _loadingAddress = '';
      });
    }
  }

  void _onMapTap(LatLng position) {
    setState(() => _selectedLocation = position);
    _reverseGeocode(position);
  }

  // 🔹 “Use Current Location” button logic
  Future<void> _useCurrentLocation() async {
    setState(() => _loadingAddress = 'Fetching current location...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final current = LatLng(pos.latitude, pos.longitude);

      setState(() => _selectedLocation = current);
      await _reverseGeocode(current);
    } catch (e) {
      setState(() => _loadingAddress = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Could not get current location: $e')),
      );
    }
  }

  // 🔹 Sign-up submission
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthApi.signup(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _restaurantController.text.trim(),
        _addressController.text.trim(),
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Account created successfully! Please log in.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Signup failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text('Register Your Restaurant',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _restaurantController,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant Name',
                    prefixIcon: Icon(Icons.store),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter restaurant name' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your username' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Restaurant Location:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use Current Location'),
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _selectedLocation,
                        initialZoom: 15,
                        onTap: (tapPosition, point) => _onMapTap(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation,
                              width: 60,
                              height: 60,
                              child: const Icon(Icons.location_on,
                                  color: Colors.red, size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                if (_loadingAddress.isNotEmpty)
                  Text(_loadingAddress,
                      style: const TextStyle(color: Colors.grey)),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Restaurant Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Select or detect a location' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _signup,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(_isLoading ? 'Creating account...' : 'Sign Up'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
