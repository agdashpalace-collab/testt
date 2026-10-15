import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> recordAttendance({
    required String workerId,
    required String workerName,
    required String type, // 'CHECK_IN' veya 'CHECK_OUT'
    required File? selfieFile,
    required String qrPayload,
  }) async {
    String selfieUrl = "";

    if (selfieFile != null && await selfieFile.exists()) {
      final timestampMs = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage
          .ref()
          .child('attendance_selfies')
          .child('${workerId}_$timestampMs.jpg');

      final uploadTask = await storageRef.putFile(
        selfieFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      selfieUrl = await uploadTask.ref.getDownloadURL();
    }

    final logRef = _firestore.collection('attendance_logs').doc();

    await logRef.set({
      'log_id': logRef.id,
      'worker_id': workerId,
      'worker_name': workerName,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'selfie_url': selfieUrl,
      'qr_payload': qrPayload,
      'device_info': 'Flutter Mobile App',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<QuerySnapshot> streamWorkerRecentLogs(String workerId) {
    return _firestore
        .collection('attendance_logs')
        .where('worker_id', isEqualTo: workerId)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }
}