import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneOrEmailController = TextEditingController();
  final _passwordController = TextEditingController(text: '123456');
  bool _isDefaultPassword = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await AuthService().signIn(
        phoneOrEmail: _phoneOrEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Firebase authStateChanges tetiklenir ve AuthGate kullanıcının rolüne göre
      // Admin ise otomatik AdminHomeScreen, İşçi ise WorkerHomeScreen açar!
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Giriş Başarısız: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.shield_outlined, size: 38, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "OLİQARX KLUB",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 28),

                  // Telefon nömrəsi (+994 sabit, 50 123 45 67)
                  TextFormField(
                    controller: _phoneOrEmailController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Telefon nömrəsi",
                      prefixText: "+994 ",
                      hintText: "50 123 45 67",
                      prefixIcon: const Icon(Icons.phone_android_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Zəhmət olmasa telefon nömrənizi daxil edin" : null,
                  ),
                  const SizedBox(height: 16),

                  // Şifrə
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onTap: () {
                      if (_isDefaultPassword) {
                        _passwordController.clear();
                        setState(() => _isDefaultPassword = false);
                      }
                    },
                    onChanged: (v) {
                      if (_isDefaultPassword) {
                        setState(() => _isDefaultPassword = false);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Şifrə",
                      hintText: "••••••",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? "Şifrə ən az 6 simvol olmalıdır" : null,
                  ),
                  const SizedBox(height: 24),

                  // 1. DAXİL OL BUTONU
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, size: 20),
                                SizedBox(width: 8),
                                Text("Daxil ol", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. QEYDİYYAT BUTONU (DAXİL OL BUTONUNUN HEMEN ALTINDA, EYNİ DİZAYNDA, FƏRQLİ RƏNGLİ)
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669), // Zümrüd yaşılı
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_outlined, size: 20),
                          SizedBox(width: 8),
                          Text("Qeydiyyat", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}