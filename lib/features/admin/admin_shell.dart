import 'package:flutter/material.dart';

import 'package:apk_absensi/features/admin/screens/admin_akun_screen.dart';
import 'package:apk_absensi/features/admin/screens/admin_beranda_screen.dart';
import 'package:apk_absensi/features/admin/screens/admin_evaluasi_screen.dart';
import 'package:apk_absensi/features/admin/screens/kelola_peserta_screen.dart';
import 'package:apk_absensi/features/admin/screens/rekap_presensi_screen.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

/// Panel admin: 5 tab (Beranda, Peserta, Presensi, Evaluasi, Akun).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.profil});

  final ProfilAkun profil;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AdminBerandaScreen(
            profil: widget.profil,
            onTab: (i) => setState(() => _index = i),
          ),
          const KelolaPesertaScreen(),
          const RekapPresensiScreen(),
          const AdminEvaluasiScreen(),
          AdminAkunScreen(profil: widget.profil),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: 'Peserta'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check_rounded),
              label: 'Presensi'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Evaluasi'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Akun'),
        ],
      ),
    );
  }
}

