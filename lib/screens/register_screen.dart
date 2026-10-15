import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  
  String _selectedAzPrefix = "50"; // Azerbaycan operatör kodları (50, 51, 55, 70, 77, 99)
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _passwordConfirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Girdiğiniz şifreler birbiriyle eşleşmiyor!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final formattedPhone = "+994 $_selectedAzPrefix ${_phoneController.text.trim()}";

      await AuthService().signUp(
        fullName: _fullNameController.text.trim(),
        phone: formattedPhone,
        password: _passwordController.text.trim(),
      );

      // Başarılı kayıt sonrası AuthGate otomatik olarak WorkerHomeScreen açar
      if (mounted) {
        Navigator.pop(context); // Register ekranından çık
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kayıt Başarısız: ${e.toString()}"),
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
      appBar: AppBar(
        title: const Text("Yeni Üye Kaydı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "PDKS Hesabı Oluştur",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                const Text(
                  "İsim, Azerbaycan telefon numaranız ve şifreniz ile anında kaydolun",
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),

                // 1. İSİM VE SOYİSİM
                TextFormField(
                  controller: _fullNameController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: "İsim ve Soyisim *",
                    hintText: "Örn: Elmir Memmedov",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Lütfen ad ve soyadınızı yazınız" : null,
                ),
                const SizedBox(height: 16),

                // 2. AZERBAYCAN MOBİL TELEFON NUMARASI (+994)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ülke Kodu ve Operatör Prefix Seçici
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: Row(
                        children: [
                          const Text("🇦🇿 +994 ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedAzPrefix,
                              items: const [
                                DropdownMenuItem(value: "50", child: Text("50")),
                                DropdownMenuItem(value: "51", child: Text("51")),
                                DropdownMenuItem(value: "55", child: Text("55")),
                                DropdownMenuItem(value: "70", child: Text("70")),
                                DropdownMenuItem(value: "77", child: Text("77")),
                                DropdownMenuItem(value: "99", child: Text("99")),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedAzPrefix = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 7 Haneli Telefon Numarası
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 7,
                        decoration: InputDecoration(
                          labelText: "Telefon Numarası *",
                          hintText: "1234567",
                          counterText: "",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) => (v == null || v.replaceAll(RegExp(r'[^0-9]'), '').length < 7)
                            ? "7 haneli numaranızı yazınız"
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. ŞİFRE (1. KEZ)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Şifre (En az 6 karakter) *",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? "Şifre en az 6 karakter olmalıdır" : null,
                ),
                const SizedBox(height: 16),

                // 4. ŞİFRE TEKRAR (2. KEZ KONTROL İÇİN)
                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: _obscurePasswordConfirm,
                  decoration: InputDecoration(
                    labelText: "Şifre Tekrar (Doğrulama) *",
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePasswordConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Lütfen şifrenizi tekrar yazınız";
                    if (v != _passwordController.text) return "Şifreler birbiriyle eşleşmiyor!";
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // KAYIT OL BUTONU
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Kayıt Ol & Hesabı Aç", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  "ℹ️ Herkes doğrudan personel olarak kaydedilir. Yönetici yetkisi verilmek istendiğinde amir tarafından Yönetici Menüsünden atanır.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}