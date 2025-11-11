import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api/auth_api.dart';
import '../../services/api_service.dart';
import '../dashboard/main_dashboard_screen.dart';
import '../drivers/driver_dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _usernameOrEmail = '';
  String _password = '';
  bool _loading = false;
  bool _obscurePassword = true;

  // =========================================================
  // 🔐 LOGIN FUNCTION
  // =========================================================
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);

    try {
      // 1️⃣ Try DRIVER LOGIN
      final driverData = await AuthApi.loginDriver(_usernameOrEmail, _password);
      if (driverData != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', driverData['access']);
        await prefs.setString('refresh_token', driverData['refresh']);
        await prefs.setInt('driver_id', driverData['driver_id']);
        await prefs.setString('driver_name', driverData['full_name'] ?? 'Driver');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🚛 Welcome, ${driverData['full_name'] ?? 'Driver'}!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DriverDashboardScreen(driverId: driverData['driver_id']),
          ),
        );
        return;
      }

      // 2️⃣ Try USER LOGIN
      final userSuccess = await AuthApi.loginUser(_usernameOrEmail, _password);
      if (userSuccess) {
        final response = await ApiService.get("accounts/me/");
        final profile = jsonDecode(response.body);
        if (!mounted) return;

        final username = profile['username'] ?? 'User';
        final role = profile['role'] ?? 'restaurant';
        final driverId = profile['driver_id'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('👋 Welcome, $username!')),
        );

        if (role == 'driver') {
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

      // 3️⃣ Invalid credentials
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
  // 🧾 UI DESIGN
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final darwcosGreen = const Color(0xFF015704);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🦅 LOGO
                Row(
                  children: [
                    Image.asset('assets/black_philippine_eagle.png',
                        height: 40, fit: BoxFit.contain),
                    const SizedBox(width: 8),
                    Text(
                      'DARWCOS',
                      style: TextStyle(
                        color: darwcosGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 50),

                // 💬 Welcome text
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Let's continue in making the world a better place one step at a time.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // 👤 Username or Email
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Username or Email',
                    hintText: 'Enter your Username or Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: darwcosGreen),
                    ),
                  ),
                  onSaved: (v) => _usernameOrEmail = v!.trim(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your username or email' : null,
                ),
                const SizedBox(height: 20),

                // 🔑 Password
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: darwcosGreen),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
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
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: darwcosGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ✅ SIGN IN BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darwcosGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white, // 👈 fixed color
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // Divider
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('or'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // 🟢 Social Buttons
                _socialButton(
                  icon: 'assets/google.png',
                  text: 'Sign In with Google',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _socialButton(
                  icon: 'assets/apple.png',
                  text: 'Sign In with Apple',
                  onTap: () {},
                ),

                const SizedBox(height: 30),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    ),
                    child: const Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
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

  // =========================================================
  // 🔘 Social Button Widget
  // =========================================================
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, height: 22),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
