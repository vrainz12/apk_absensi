import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:apk_absensi/core/constants/magang_constants.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';
import 'package:apk_absensi/features/dashboard/presentation/services/face_recognition_service.dart';

class PresensiTab extends StatefulWidget {
  final VoidCallback? onAbsen;
  final VoidCallback? onBack;
  final String? jamMasuk;
  final String? jamPulang;

  const PresensiTab({
    super.key,
    this.onAbsen,
    this.onBack,
    this.jamMasuk,
    this.jamPulang,
  });

  @override
  State<PresensiTab> createState() => _PresensiTabState();
}

class _PresensiTabState extends State<PresensiTab> {
  CameraController? _cameraController;
  final LocalAuthentication _auth = LocalAuthentication();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FaceRecognitionService _face = FaceRecognitionService();
  final TextEditingController _keteranganC = TextEditingController();

  final Color _primaryGreen = const Color(0xFF1B4332);
  final Color _bgCream = const Color(0xFFFFF8F4);
  final Color _accentCoral = const Color(0xFFFFB09C);

  int _selectedTab = 0;
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  bool _isFingerprintVerified = false;
  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _isSubmitting = false;
  XFile? _capturedImage;

  bool _isCheckingFace = false;
  bool _isFaceValid = false;
  String _faceStatus = 'Menunggu foto wajah';

  Position? _currentPosition;
  bool _isCheckingLocation = false;
  bool _isLocationValid = false;
  String _locationStatus = 'Mengecek lokasi...';
  bool _isWfh = false; // Mode presensi: WFO (Kantor) atau WFH (Rumah)

  final double _targetLatitude = -6.928195; // Pastikan ini koordinat kantormu
  final double _targetLongitude = 107.638556;
  final double _maxRadiusInMeters = 100.0; // Radius aman kantor

  @override
  void initState() {
    super.initState();
    _initCameraOtomatis();
    _checkLocationAndGeofence();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _cameraController?.dispose();
    _face.dispose();
    _keteranganC.dispose();
    super.dispose();
  }

  String _formatTime(int value) => value.toString().padLeft(2, '0');

  Future<void> _checkLocationAndGeofence() async {
    setState(() {
      _isCheckingLocation = true;
      _locationStatus = 'Mengambil lokasi GPS...';
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _isLocationValid = false;
          _locationStatus = 'GPS tidak aktif. Nyalakan GPS HP Anda!';
        });
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _isCheckingLocation = false;
            _isLocationValid = false;
            _locationStatus = 'Izin lokasi ditolak.';
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _isLocationValid = false;
          _locationStatus = 'Izin lokasi ditolak permanen.';
        });
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _targetLatitude,
        _targetLongitude,
      );

      final jarakStr = distanceInMeters >= 1000
          ? '${(distanceInMeters / 1000).toStringAsFixed(1)} km'
          : '${distanceInMeters.toStringAsFixed(1)}m';

      bool isValid = _isWfh || (distanceInMeters <= _maxRadiusInMeters);

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationValid = isValid;
          _isCheckingLocation = false;
          if (_isWfh) {
            _locationStatus = 'Mode WFH Aktif · Koordinat GPS Terverifikasi ($jarakStr dari kantor)';
          } else {
            _locationStatus = isValid
                ? 'Lokasi Valid di Kantor ($jarakStr)'
                : 'Di luar area kantor ($jarakStr)';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
          _isLocationValid = false;
          _locationStatus = 'Gagal mendapatkan lokasi GPS.';
        });
      }
    }
  }

  // Kamera kini otomatis mencari lensa depan tanpa perlu dilempar dari shell
  Future<void> _initCameraOtomatis() async {
    if (mounted) {
      setState(() {
        _isCameraReady = false;
      });
    }

    await _cameraController?.dispose();
    _cameraController = null;

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      // Jika tab sudah ditutup selagi kamera dibuka, matikan kamera ini.
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() {
        _isCameraReady = true;
      });
    } catch (e) {
      debugPrint('Error inisialisasi kamera: $e');
      await controller?.dispose();
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      setState(() {
        _isCapturing = true;
      });

      final XFile image = await _cameraController!.takePicture();

      if (mounted) {
        setState(() {
          _capturedImage = image;
          _isCapturing = false;
          _isCheckingFace = true;
          _isFaceValid = false;
          _faceStatus = 'Memeriksa wajah...';
        });
      }

      await _validateFace(image.path);
    } catch (e) {
      debugPrint('Error jepret foto: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _validateFace(String path) async {
    String? masalah;
    try {
      masalah = await _face.cekFoto(path);
    } catch (e) {
      debugPrint('Error cek wajah: $e');
      masalah = 'Gagal memeriksa wajah. Coba foto ulang.';
    }

    if (!mounted) return;
    setState(() {
      _isCheckingFace = false;
      _isFaceValid = masalah == null;
      _faceStatus = masalah ?? 'Wajah terdeteksi';
    });
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
      _isCheckingFace = false;
      _isFaceValid = false;
      _faceStatus = 'Menunggu foto wajah';
    });
  }

  Future<void> _authenticateFingerprint() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      if (!canAuthenticateWithBiometrics) return;

      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk konfirmasi absensi',
        biometricOnly: true,
      );

      if (authenticated && mounted) {
        setState(() {
          _isFingerprintVerified = true;
        });
      }
    } catch (e) {
      debugPrint('Error Fingerprint: $e');
    }
  }

  void _prosesKirim() {
    final now = DateTime.now();
    final isMasuk = _selectedTab == 0;
    final telat = isMasuk && MagangConstants.isTerlambat(now);
    final pulangAwal = !isMasuk && MagangConstants.isPulangAwal(now);

    // Validasi alasan jika terlambat
    if (telat && _keteranganC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presensi masuk lewat pukul 09:00 WIB (Terlambat). Wajib mengisi alasan mengapa telat!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validasi alasan jika pulang lebih awal
    if (pulangAwal && _keteranganC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Presensi pulang sebelum pukul 16:00 WIB. Wajib mengisi alasan mengapa pulang lebih awal!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Peringatan jika lewat jam 17:00
    if (!isMasuk && (now.hour > MagangConstants.jamPulangBatas ||
        (now.hour == MagangConstants.jamPulangBatas && now.minute > MagangConstants.menitPulangBatas))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peringatan: Absen pulang telah melewati batas maksimal pukul 17:00 WIB!'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi GPS belum didapatkan! Nyalakan GPS HP Anda.'), backgroundColor: Colors.red));
      return;
    }

    if (!_isWfh && !_isLocationValid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamu berada di luar area kantor! Aktifkan mode Presensi WFH jika bekerja dari rumah.'), backgroundColor: Colors.red));
      return;
    }
    if (!_isFingerprintVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan verifikasi Sidik Jari terlebih dahulu!'), backgroundColor: Colors.orange));
      return;
    }
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan Ambil Foto terlebih dahulu!'), backgroundColor: Colors.orange));
      return;
    }
    if (_isCheckingFace) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sedang memeriksa wajah, harap tunggu...'), backgroundColor: Colors.orange));
      return;
    }
    if (!_isFaceValid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wajah tidak valid! Silakan "Foto Ulang".'), backgroundColor: Colors.red));
      return;
    }

    _submitPresensi();
  }

  Future<void> _submitPresensi() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final Uint8List? compressedBytes = await FlutterImageCompress.compressWithFile(
        _capturedImage!.path,
        minWidth: 400,
        minHeight: 400,
        quality: 30,
      );

      if (compressedBytes == null) throw Exception('Gagal mengompres foto!');

      String fileName = 'absensi_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage
          .from('presensi_photos')
          .uploadBinary(fileName, compressedBytes);

      final String fotoUrl = _supabase.storage.from('presensi_photos').getPublicUrl(fileName);

      final now = DateTime.now();
      final isMasuk = _selectedTab == 0;
      final telat = isMasuk && MagangConstants.isTerlambat(now);
      final pulangAwal = !isMasuk && MagangConstants.isPulangAwal(now);
      final tipeAbsen = isMasuk
          ? (_isWfh ? 'Masuk (WFH)' : 'Masuk')
          : (_isWfh ? 'Pulang (WFH)' : 'Pulang');

      final keterangan = _keteranganC.text.trim();

      await _supabase.from('presensi_logs').insert({
        'user_id': AuthService.userId,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'timestamp': now.toUtc().toIso8601String(),
        'biometric_status': 'Verified',
        'foto_url': fotoUrl,
        'tipe_absen': tipeAbsen,
        'keterangan': keterangan.isNotEmpty ? keterangan : null,
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        String pesanSukses;
        final wfhLabel = _isWfh ? ' [WFH]' : '';
        if (isMasuk) {
          pesanSukses = telat
              ? 'Presensi Masuk$wfhLabel Berhasil! (Status: Terlambat, lewat 09:00)'
              : 'Presensi Masuk$wfhLabel Berhasil! (Status: Tepat Waktu)';
        } else {
          pesanSukses = pulangAwal
              ? 'Presensi Pulang$wfhLabel Berhasil! (Status: Pulang Lebih Awal)'
              : 'Presensi Pulang$wfhLabel Berhasil Disimpan!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesanSukses),
            backgroundColor: (telat || pulangAwal) ? Colors.orange.shade800 : _primaryGreen,
          ),
        );

        // Memanggil fungsi eksternal jika ada (dari main_shell), lalu me-reset formulir
        if (widget.onAbsen != null) {
          widget.onAbsen!();
        }
        _retakePicture();
        _keteranganC.clear();
        setState(() {
          _isFingerprintVerified = false;
        });
      }
    } catch (e) {
      debugPrint('Error submit API: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String jamRealtime = "${_formatTime(_currentTime.hour)}:${_formatTime(_currentTime.minute)}:${_formatTime(_currentTime.second)} WIB";
    String tanggalHariIni = "${_currentTime.day}/${_currentTime.month}/${_currentTime.year}";

    final Color faceColor = _capturedImage == null
        ? Colors.grey
        : (_isCheckingFace
            ? Colors.orange
            : (_isFaceValid ? Colors.green : Colors.redAccent));

    return Scaffold(
      backgroundColor: _bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _primaryGreen),
          tooltip: 'Kembali',
          onPressed: widget.onBack ?? () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "Mulai hari baikmu.",
          style: TextStyle(color: _primaryGreen, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TAB PILIHAN (MASUK / PULANG)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? _primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Masuk",
                          style: TextStyle(
                            color: _selectedTab == 0 ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? _primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Pulang",
                          style: TextStyle(
                            color: _selectedTab == 1 ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. KOTAK INFORMASI WAKTU REAL-TIME
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: _primaryGreen),
                          const SizedBox(width: 6),
                          Text(tanggalHariIni, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        jamRealtime,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _primaryGreen),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentCoral.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.brown),
                        SizedBox(width: 4),
                        Text("Real-time", style: TextStyle(color: Colors.brown, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. STATUS LOKASI GEOFENCING & OPSI WFH
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Lokasi & Mode Kerja",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      TextButton.icon(
                        onPressed: _checkLocationAndGeofence,
                        icon: _isCheckingLocation
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _primaryGreen))
                            : const Icon(Icons.refresh, size: 16),
                        label: const Text("Perbarui"),
                        style: TextButton.styleFrom(foregroundColor: _primaryGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Mode Switcher: WFO vs WFH
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isWfh = false;
                              });
                              _checkLocationAndGeofence();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isWfh ? _primaryGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'WFO (Kantor)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !_isWfh ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isWfh = true;
                                _isLocationValid = true;
                              });
                              _checkLocationAndGeofence();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isWfh ? const Color(0xFF2B6CB0) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'WFH (Luar Kantor)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isWfh ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isWfh
                          ? const Color(0xFFEBF8FF)
                          : (_isLocationValid
                              ? _primaryGreen.withValues(alpha: 0.05)
                              : Colors.red.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isWfh
                                ? Icons.home_work_rounded
                                : (_isLocationValid ? Icons.my_location : Icons.location_off),
                            color: _isWfh
                                ? const Color(0xFF2B6CB0)
                                : (_isLocationValid ? _primaryGreen : Colors.redAccent),
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              _locationStatus,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isWfh
                                    ? const Color(0xFF2B6CB0)
                                    : (_isLocationValid ? _primaryGreen : Colors.redAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!_isWfh && !_isLocationValid && _currentPosition != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: Color(0xFFC2410C)),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tidak di kantor? Kamu bisa beralih ke Presensi WFH.',
                              style: TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              backgroundColor: const Color(0xFFC2410C),
                              foregroundColor: Colors.white,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () {
                              setState(() {
                                _isWfh = true;
                                _isLocationValid = true;
                              });
                              _checkLocationAndGeofence();
                            },
                            child: const Text('Mode WFH',
                                style: TextStyle(
                                    fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. VERIFIKASI SIDIK JARI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: _isFingerprintVerified ? _primaryGreen : Colors.grey,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Verifikasi Sidik Jari", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          _isFingerprintVerified
                              ? 'Berhasil diverifikasi'
                              : 'Belum diverifikasi',
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _authenticateFingerprint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(_isFingerprintVerified ? 'Ulangi' : 'Pindai', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. AREA KAMERA & VERIFIKASI WAJAH
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Foto kehadiran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text("Tampilkan wajah dengan jelas", style: TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 12),

                  // Frame Kamera
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _isCapturing
                          ? Center(child: CircularProgressIndicator(color: _accentCoral))
                          : _capturedImage != null
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: ElevatedButton.icon(
                                        onPressed: _retakePicture,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text("Foto Ulang", style: TextStyle(fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                )
                              : _isCameraReady
                                  ? LayoutBuilder(
                                      builder: (context, constraints) {
                                        double cameraRatio = _cameraController!.value.aspectRatio;
                                        if (cameraRatio > 1) cameraRatio = 1 / cameraRatio;

                                        final double containerRatio = constraints.maxWidth / constraints.maxHeight;
                                        double scale = cameraRatio / containerRatio;
                                        if (scale < 1) scale = 1 / scale;

                                        return ClipRect(
                                          child: Transform.scale(
                                            scale: scale,
                                            child: Center(
                                              child: CameraPreview(_cameraController!),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Center(child: CircularProgressIndicator(color: _accentCoral)),
                    ),
                  ),

                  // TOMBOL AMBIL FOTO MANUAL
                  if (_isFingerprintVerified && _capturedImage == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _takePicture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text("Ambil Foto", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _isCheckingFace
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryGreen))
                          : Icon(
                              _isFaceValid ? Icons.face_retouching_natural : Icons.face_retouching_off,
                              size: 18,
                              color: faceColor,
                            ),
                      const SizedBox(width: 8),
                      Text(
                        _faceStatus,
                        style: TextStyle(fontSize: 12, color: faceColor == Colors.grey ? Colors.black54 : faceColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. FORM KETERANGAN JIKA TELAT ATAU PULANG LEBIH AWAL
            Builder(
              builder: (context) {
                final bool isTelat = _selectedTab == 0 && MagangConstants.isTerlambat(_currentTime);
                final bool isPulangAwal = _selectedTab == 1 && MagangConstants.isPulangAwal(_currentTime);

                if (!isTelat && !isPulangAwal) return const SizedBox.shrink();

                final menitTelat = MagangConstants.menitKeterlambatan(_currentTime);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isTelat ? const Color(0xFFFFF5F5) : const Color(0xFFFFF9DB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isTelat ? const Color(0xFFFFC9C9) : const Color(0xFFFFEC99),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isTelat ? Icons.warning_amber_rounded : Icons.departure_board_rounded,
                              color: isTelat ? Colors.redAccent : const Color(0xFFE8590C),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isTelat
                                    ? 'Alasan Keterlambatan (Wajib Diisi)'
                                    : 'Alasan Pulang Lebih Awal (Wajib Diisi)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isTelat ? Colors.redAccent : const Color(0xFFE8590C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTelat
                              ? 'Presensi masuk dilakukan lewat pukul 09:00 WIB (Terlambat $menitTelat menit). Mohon jelaskan alasan mengapa Anda terlambat.'
                              : 'Presensi pulang dilakukan sebelum jam kerja selesai (16:00 WIB). Mohon jelaskan alasan mengapa Anda pulang lebih awal.',
                          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _keteranganC,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: isTelat
                                ? 'Tuliskan alasan telat (mis: macet parah, ban bocor, kendala teknis)...'
                                : 'Tuliskan alasan pulang awal (mis: izin berobat, ada keperluan mendesak)...',
                            hintStyle: const TextStyle(fontSize: 12, color: Colors.black38),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isTelat ? const Color(0xFFFFC9C9) : const Color(0xFFFFEC99),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isTelat ? const Color(0xFFFFC9C9) : const Color(0xFFFFEC99),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isTelat ? Colors.redAccent : const Color(0xFFE8590C),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // 7. TOMBOL KIRIM ABSENSI KE SUPABASE
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSubmitting ? null : _prosesKirim,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(
                  _isSubmitting
                      ? 'Mengirim...'
                      : 'Kirim Absensi ${_selectedTab == 0 ? 'Masuk' : 'Pulang'}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}