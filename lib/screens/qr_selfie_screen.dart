import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/attendance_service.dart';

class QrSelfieScreen extends StatefulWidget {
  final String attendanceType; // 'CHECK_IN' veya 'CHECK_OUT'

  const QrSelfieScreen({super.key, required this.attendanceType});

  @override
  State<QrSelfieScreen> createState() => _QrSelfieScreenState();
}

class _QrSelfieScreenState extends State<QrSelfieScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  CameraController? _frontCameraController;
  bool _isProcessing = false;
  String _statusMessage = "Lütfen kapıdaki QR kodu hizalayınız";

  @override
  void initState() {
    super.initState();
    _initFrontCameraForSelfie();
  }

  /// Ön kamerayı hazırla (QR okunduğu an sıfır gecikmeyle selfie çekebilmek için)
  Future<void> _initFrontCameraForSelfie() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _frontCameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _frontCameraController!.initialize();
    } catch (e) {
      debugPrint("Ön kamera hatası: $e");
    }
  }

  /// QR kod algılandığında tetiklenen ana metot
  Future<void> _onBarcodeScanned(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "QR Doğrulandı! Anlık selfie alınıyor... 📸";
    });

    await _scannerController.stop();

    try {
      File? selfieFile;

      // 1. ADIM: Ön kameradan otomatik selfie yakala
      if (_frontCameraController != null && _frontCameraController!.value.isInitialized) {
        final XFile photo = await _frontCameraController!.takePicture();
        selfieFile = File(photo.path);
      }

      setState(() {
        _statusMessage = "Fotoğraf yükleniyor ve kayıt oluşturuluyor...";
      });

      // 2. ADIM: Firebase Storage ve Firestore'a kaydet
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Oturum bulunamadı!");

      await AttendanceService().recordAttendance(
        workerId: currentUser.uid,
        workerName: currentUser.displayName ?? "İşçi Personel",
        type: widget.attendanceType,
        selfieFile: selfieFile,
        qrPayload: qrData,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red),
        );
        setState(() {
          _isProcessing = false;
          _statusMessage = "Lütfen kapıdaki QR kodu hizalayınız";
        });
        _scannerController.start();
      }
    }
  }

  void _showSuccessDialog() {
    final isCheckIn = widget.attendanceType == 'CHECK_IN';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: isCheckIn ? Colors.green : Colors.orange,
          size: 64,
        ),
        title: Text(isCheckIn ? "Giriş Başarılı" : "Çıkış Başarılı"),
        content: Text(
          isCheckIn
              ? "Vardiya girişiniz ve selfie görseliniz sisteme kaydedildi. İyi çalışmalar!"
              : "Vardiya çıkışınız sisteme kaydedildi. İyi dinlenmeler!",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Tamam"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _frontCameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attendanceType == 'CHECK_IN' ? "Vardiya Giriş (QR)" : "Vardiya Çıkış (QR)"),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeScanned,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.qr_code_scanner, color: Colors.amber),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    "Güvenlik gereği QR okunduğu an kimlik teyidi için anlık selfie alınmaktadır.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}