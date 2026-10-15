import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import 'qr_selfie_screen.dart';

class WorkerHomeScreen extends StatelessWidget {
  final User user;
  final Map<String, dynamic> userData;

  const WorkerHomeScreen({
    super.key,
    required this.user,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = userData['fullName'] ?? user.displayName ?? "İşçi Personel";
    final workerId = userData['worker_id'] ?? "SICIL-0000";
    final department = userData['department'] ?? "Saha Personeli";
    final dateStr = DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('İşçi Devam Portalı'),
        backgroundColor: Colors.white,
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kullanıcı Bilgi Kartı
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : "İ",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text("$workerId • $department", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Oturum Açık / İşçi Arayüzü",
                            style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Giriş Yap Butonu (QR + Selfie)
            _buildActionButton(
              title: "Vardiyaya Giriş Yap (QR)",
              subtitle: "Kapıdaki QR'ı okut & anlık selfie çek",
              icon: Icons.login,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrSelfieScreen(attendanceType: 'CHECK_IN')),
                );
              },
            ),

            const SizedBox(height: 14),

            // Çıkış Yap Butonu (QR + Selfie)
            _buildActionButton(
              title: "Vardiyadan Çıkış Yap (QR)",
              subtitle: "Mesai bitiminde QR okut & selfie teyit",
              icon: Icons.logout,
              color: const Color(0xFFF97316),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrSelfieScreen(attendanceType: 'CHECK_OUT')),
                );
              },
            ),

            const SizedBox(height: 26),

            // Son Hareketlerim Başlığı
            const Text(
              "Son Giriş / Çıkış Hareketlerim",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Gerçek Zamanlı Firestore Stream
            StreamBuilder(
              stream: AttendanceService().streamWorkerRecentLogs(user.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Text("Henüz giriş/çıkış kaydınız bulunmuyor.", textAlign: TextAlign.center),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isCheckIn = data['type'] == 'CHECK_IN';
                    final time = data['created_at'] != null ? data['created_at'].toString().substring(11, 16) : "--:--";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCheckIn ? Colors.green.shade50 : Colors.orange.shade50,
                          child: Icon(
                            isCheckIn ? Icons.login : Icons.logout,
                            color: isCheckIn ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(isCheckIn ? "Vardiya Girişi" : "Vardiya Çıkışı", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Selfie Onaylandı • Saat: $time"),
                        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesaptan Çıkış Yapılsın mı?'),
        content: const Text('Çıkış yaparsanız ana giriş sayfasına yönlendirileceksiniz.'),
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

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}