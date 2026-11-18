import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/features/admin/admin_shell.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';
import 'package:apk_absensi/features/auth/login_screen.dart';
import 'package:apk_absensi/features/shell/main_shell.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  ProfilAkun? _profil;
  bool _memeriksa = true;
  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    _periksaSesi();

    // Setiap kali pengguna keluar (dari layar mana pun), kembali ke login.
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut && mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        setState(() => _profil = null);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // Sesi login disimpan otomatis oleh Supabase, jadi pengguna tidak perlu
  // login ulang setiap membuka aplikasi.
  Future<void> _periksaSesi() async {
    ProfilAkun? p;
    try {
      p = await AuthService.profilSaatIni();
    } catch (e) {
      debugPrint('Gagal memeriksa sesi: $e');
    }
    if (!mounted) return;
    setState(() {
      _profil = p;
      _memeriksa = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_memeriksa) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.green)),
      );
    }

    final p = _profil;
    if (p == null) {
      return LoginScreen(onBerhasil: (profil) => setState(() => _profil = profil));
    }

    if (p.isAdmin) {
      return AdminShell(key: ValueKey(p.id), profil: p);
    }
    return MainShell(key: ValueKey(p.id), cameras: widget.cameras);
  }
}