import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api/auth_api.dart';
import '../../services/api_service.dart';
import '../dashboard/main_dashboard_screen.dart';
import '../drivers/driver_dashboard_screen.dart';
import 'signup_screen.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  bool _loading = false;
  bool _obscurePassword = true;

  // =========================================================
  // 🔐 LOGIN FUNCTION (tries Driver first, then Restaurant/Employee)
  // =========================================================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    try {
      // ------------------------------------------------------
      // 🚛 1️⃣ Try DRIVER LOGIN first
      // ------------------------------------------------------
      final driverData = await AuthApi.loginDriver(_username, _password);
      if (driverData != null) {
        if (!mounted) return;

        // ✅ Save driver details to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', driverData['access']);
        await prefs.setString('refresh_token', driverData['refresh']);
        await prefs.setInt('driver_id', driverData['driver_id']);
        await prefs.setString('driver_name', driverData['full_name'] ?? 'Driver');

        final driverId = driverData['driver_id'];
        final driverName = driverData['full_name'] ?? 'Driver';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🚛 Welcome, $driverName!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DriverDashboardScreen(driverId: driverId),
          ),
        );
        return;
      }

      // ------------------------------------------------------
      // 🧍 2️⃣ Otherwise, try RESTAURANT/EMPLOYEE login
      // ------------------------------------------------------
      final userSuccess = await AuthApi.loginUser(_username, _password);
      if (userSuccess) {
        final response = await ApiService.get("accounts/me/");
        final Map<String, dynamic> profile = jsonDecode(response.body);
        if (!mounted) return;

        print("👤 Profile data: $profile");

        final username = profile['username'] ?? 'User';
        final role = profile['role'] ?? 'restaurant';
        final driverId = profile['driver_id'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('👋 Welcome, $username!')),
        );

        if (role == 'driver') {
          print("🆔 Navigating with driverId: $driverId");
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('driver_id', driverId);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DriverDashboardScreen(driverId: driverId),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainDashboardScreen(),
            ),
          );
        }
        return;
      }
      // ------------------------------------------------------
      // ❌ 3️⃣ If both fail
      // ------------------------------------------------------
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Login failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // =========================================================
  // 🧾 UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'User Login',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login as Restaurant Owner or Driver',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // 🧍 Username / Email Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Username or Email',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => _username = v!.trim(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your username or email' : null,
                ),
                const SizedBox(height: 16),

                // 🔑 Password Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  onSaved: (v) => _password = v!.trim(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your password' : null,
                ),
                const SizedBox(height: 24),

                // 🚪 Login Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(_loading ? 'Logging in...' : 'Login'),
                    onPressed: _loading ? null : _login,
                  ),
                ),
                const SizedBox(height: 16),

                // 📝 Signup Link (Only for restaurant owners)
                TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Sign Up'),
                              content: const Text(
                                'Driver accounts are created by the administrator.\n\n'
                                'Only restaurant owners can sign up manually.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignupScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('Restaurant Sign Up'),
                                ),
                              ],
                            ),
                          );
                        },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
