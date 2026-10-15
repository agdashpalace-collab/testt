import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PdksApp());
}

class PdksApp extends StatelessWidget {
  const PdksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vardiya PDKS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

/// [AuthGate]: Kalıcı Oturum & Rol Tabanlı Yönlendirme.
/// 1. Kullanıcı oturum açmamışsa -> LoginScreen
/// 2. Kullanıcı oturum açmışsa Firestore 'users/{uid}' belgesindeki 'role' kontrol edilir:
///    - 'ADMIN' ise -> AdminHomeScreen (Yönetici Mobil Paneli)
///    - 'WORKER' ise -> WorkerHomeScreen (İşçi QR & Selfie Paneli)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Oturum durumu kontrol ediliyor
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Giriş yapılmış oturum yoksa Giriş Ekranını aç
        final currentUser = authSnapshot.data;
        if (currentUser == null) {
          return const LoginScreen();
        }

        // Kullanıcı giriş yapmış -> Firestore'dan Rolünü çek (Worker vs Admin)
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Kullanıcı yetkileri doğrulanıyor..."),
                    ],
                  ),
                ),
              );
            }

            final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
            final role = userData?['role'] ?? 'WORKER';

            // YÖNETİCİ İSE YÖNETİCİ MOBİL ARAYÜZÜNÜ AÇ
            if (role == 'ADMIN') {
              return AdminHomeScreen(user: currentUser, userData: userData ?? {});
            }

            // İŞÇİ İSE İŞÇİ MOBİL ARAYÜZÜNÜ AÇ
            return WorkerHomeScreen(user: currentUser, userData: userData ?? {});
          },
        );
      },
    );
  }
}