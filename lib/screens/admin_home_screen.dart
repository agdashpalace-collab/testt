import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminHomeScreen extends StatelessWidget {
  final User user;
  final Map<String, dynamic> userData;

  const AdminHomeScreen({
    super.key,
    required this.user,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final adminName = userData['fullName'] ?? user.displayName ?? "Sistem Yöneticisi";

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Gece Mavisi Yönetici Teması
      appBar: AppBar(
        title: const Text('Yönetici Mobil Paneli', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          // HESAPTAN ÇIKIŞ BUTONU
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Hesaptan Çıkış Yap',
            onPressed: () => _confirmSignOut(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Yönetici Kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFF7C3AED),
                    child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(adminName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        const Text("Yetki: Tam Yönetici (Admin)", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade900.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.purple.shade400),
                          ),
                          child: const Text("YÖNETİCİ ARAYÜZÜ AKTİF", style: TextStyle(color: Color(0xFFC084FC), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Hızlı İstatistik Kartları
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard("Bugünkü Giriş", "Canlı Takip", Icons.login, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard("Toplam İşçi", "Kayıtlı Personel", Icons.people, Colors.blue),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Canlı Giriş-Çıkış ve Selfie Akışı Başlığı
            const Text(
              "Canlı Giriş-Çıkış & Özçekim Akışı",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),

            // Tüm İşçilerin Loglarını Canlı Dinle (Selfie'leri ile birlikte)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance_logs')
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                    child: const Text("Henüz bir giriş-çıkış kaydı bulunmuyor.", style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isCheckIn = data['type'] == 'CHECK_IN';
                    final workerName = data['worker_name'] ?? "Personel";
                    final selfieUrl = data['selfie_url'] ?? "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Row(
                        children: [
                          // SELFIE THUMBNAIL (Büyütmek için tıklanabilir)
                          GestureDetector(
                            onTap: () {
                              if (selfieUrl.isNotEmpty) {
                                _showHighResSelfie(context, workerName, selfieUrl, isCheckIn);
                              }
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: selfieUrl.isNotEmpty
                                      ? Image.network(selfieUrl, width: 50, height: 50, fit: BoxFit.cover)
                                      : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.slate,
                                          child: const Icon(Icons.person, color: Colors.white),
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                    child: const Icon(Icons.zoom_in, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(workerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isCheckIn ? Colors.green.shade900 : Colors.orange.shade900,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isCheckIn ? "GİRİŞ" : "ÇIKIŞ",
                                        style: TextStyle(
                                          color: isCheckIn ? Colors.greenAccent : Colors.orangeAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text("Selfie Teyitli", style: TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHighResSelfie(BuildContext context, String workerName, String url, bool isCheckIn) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(workerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(isCheckIn ? "Vardiya Giriş Özçekimi" : "Vardiya Çıkış Özçekimi", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(url, fit: BoxFit.cover, height: 280),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Kapat"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yönetici Hesabından Çıkış'),
        content: const Text('Oturum kapatılacak ve giriş ekranına dönülecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
    }
  }

  Widget _buildMetricCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}