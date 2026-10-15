import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// 1. MOBİL UYGULAMADAN YENİ HESAP KAYDI (HERKES NORMAL İŞÇİ KAYDOLUR, ŞİFRE 2 KEZ KONTROL EDİLİR)
  Future<UserCredential> signUp({
    required String fullName,
    required String phone, // Azerbaycan formatı: +994 50 123 45 67
    required String password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final email = "user_$cleanPhone@vardiya.local";

    // Firebase Auth ile yeni kullanıcı oluştur
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Firestore 'users' koleksiyonuna kaydet (Varsayılan Rol: WORKER)
    // Yönetici gerektiğinde paneldeki üyeler listesinden istediği kişiyi 'Yönetici Yap' butonuyla yetkilendirir.
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'worker_id': 'SICIL-${cleanPhone.length >= 4 ? cleanPhone.substring(cleanPhone.length - 4) : '1000'}',
      'name': firstName,
      'surname': lastName,
      'fullName': fullName.trim(),
      'phone': phone,
      'email': email,
      'department': 'Personel Kadrosu',
      'role': 'WORKER', // Herkes standart işçi olarak kaydolur
      'status': 'ACTIVE',
      'created_at': FieldValue.serverTimestamp(),
    });

    await credential.user!.updateDisplayName(fullName);
    return credential;
  }

  /// 2. HESABA GİRİŞ YAPMA (Ortak Giriş: İşçi ve Admin aynı ekrandan girer)
  Future<UserCredential> signIn({
    required String phoneOrEmail,
    required String password,
  }) async {
    String email = phoneOrEmail.trim();
    if (!email.contains('@')) {
      final clean = phoneOrEmail.replaceAll(RegExp(r'[^0-9]'), '');
      email = "user_$clean@vardiya.local";
    }

    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return credential;
  }

  /// 3. HESAPTAN ÇIKIŞ YAPMA (Logout)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// 4. KULLANICI ROLÜNÜ GETİR
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] ?? 'WORKER';
      }
    } catch (e) {
      // Hata durumunda varsayılan rol
    }
    return 'WORKER';
  }

  /// 5. YÖNETİCİ TARAFINDAN ROL GÜNCELLEME (Yönetici Yap / İşçiye Çevir)
  Future<void> updateRole(String uid, String newRole) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole,
    });
  }
}