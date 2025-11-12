import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api/auth_api.dart';
import '../dashboard/main_dashboard_screen.dart'; // redirect after success

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _restaurantController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  LatLng _selectedLocation = LatLng(7.1907, 125.4553); // Davao City
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

  // ============================================================
  // 🌍 Reverse Geocode
  // ============================================================
  Future<void> _reverseGeocode(LatLng location) async {
    setState(() => _loadingAddress = 'Fetching address...');
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${location.latitude}&lon=${location.longitude}');
      final response =
          await http.get(url, headers: {'User-Agent': 'DARWCOS/1.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? 'Unknown location';
        setState(() {
          _addressController.text = address;
          _loadingAddress = '';
        });
      } else {
        throw Exception('Reverse geocoding failed');
      }
    } catch (e) {
      setState(() {
        _addressController.text =
            'Lat: ${location.latitude.toStringAsFixed(5)}, Lng: ${location.longitude.toStringAsFixed(5)}';
        _loadingAddress = '';
      });
    }
  }

  // ============================================================
  // 📍 Handle Map Tap
  // ============================================================
  void _onMapTap(LatLng position) {
    setState(() => _selectedLocation = position);
    _reverseGeocode(position);
  }

  // ============================================================
  // 📍 Use Current Location
  // ============================================================
  Future<void> _useCurrentLocation() async {
    setState(() => _loadingAddress = 'Fetching current location...');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final current = LatLng(pos.latitude, pos.longitude);

      setState(() => _selectedLocation = current);
      await _reverseGeocode(current);
    } catch (e) {
      setState(() => _loadingAddress = '');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Could not get current location: $e')),
      );
    }
  }

  // ============================================================
  // 🧾 NORMAL SIGNUP
  // ============================================================
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthApi.signup(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        restaurantName: _restaurantController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Account created successfully! Please log in.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Signup failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // 🔐 GOOGLE SIGN-UP
  // ============================================================
  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await AuthApi.signInWithGoogle();

      if (userCredential != null) {
        final user = userCredential.user!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('👋 Welcome, ${user.displayName ?? user.email}!')),
        );

        // Optionally: create a user record in Django
        // final token = await user.getIdToken();
        // await ApiService.post('accounts/google-auth/', {
        //   "email": user.email,
        //   "name": user.displayName,
        //   "firebase_token": token,
        // });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In cancelled.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Google Sign-Up failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // 🖼️ UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final darwcosGreen = const Color(0xFF015704);

    InputDecoration _dec(String label, String hint) => InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darwcosGreen),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Image.asset('assets/black_philippine_eagle.png', height: 38),
                    const SizedBox(width: 8),
                    Text('DARWCOS',
                        style: TextStyle(
                            color: darwcosGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 28),

                Text('Get Started',
                    style: TextStyle(
                        color: darwcosGreen,
                        fontSize: 32,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('Enter your details to start your journey with us.',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 24),

                // Form Fields
                TextFormField(
                  controller: _restaurantController,
                  decoration:
                      _dec('Restaurant Name', 'Enter your Restaurant Name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your Restaurant Name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _usernameController,
                  decoration: _dec('Username', 'Enter your Username'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your Username' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  decoration: _dec('Email', 'Enter your Email'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your Email';
                    if (!v.contains('@')) return 'Enter a valid Email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _dec('Password', 'Enter your Password'),
                  validator: (v) =>
                      v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  decoration: _dec('Address', 'Enter your Address'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your Address' : null,
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label:
                        Text('Use Current Location', style: TextStyle(color: darwcosGreen)),
                  ),
                ),
                if (_loadingAddress.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(_loadingAddress,
                        style: const TextStyle(color: Colors.grey)),
                  ),

                // Map Picker
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 15,
                      onTap: (tapPos, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.darwcos',
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
                const SizedBox(height: 22),

                // ✅ Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darwcosGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _isLoading ? null : _signup,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 26),

                // Divider
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child:
                          Text('or', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // 🌐 Google Sign-Up
                _socialButton(
                  icon: 'assets/google.png',
                  text: 'Sign up with Google',
                  onTap: _signUpWithGoogle, // 👈 connected here
                ),
                const SizedBox(height: 12),
                _socialButton(
                  icon: 'assets/apple.png',
                  text: 'Sign up with Apple',
                  onTap: () {}, // (future implementation)
                ),
                const SizedBox(height: 24),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text.rich(
                      TextSpan(
                        text: 'Already have an Account? ',
                        style: const TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              color: darwcosGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔘 Social Button Widget
  Widget _socialButton({
    required String icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, height: 20),
            const SizedBox(width: 10),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
