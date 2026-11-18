import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import 'package:apk_absensi/features/presensi/presentation/screens/presensi_screen.dart';
import 'package:apk_absensi/features/presensi/izin/form_izin_screen.dart';
import 'package:apk_absensi/features/presensi/tugas/form_tugas_screen.dart';
import 'package:apk_absensi/features/profil/profil_screen.dart';
import 'package:apk_absensi/features/profil/user/user_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final List<CameraDescription> cameras;

  const DashboardScreen({super.key, required this.cameras});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  // Fungsi memunculkan peringatan untuk fitur yang belum aktif
  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Fitur $featureName akan segera hadir! 🚀"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),

      // ==========================================
      // TOMBOL ABSEN TENGAH (MENGAPUNG)
      // ==========================================
      floatingActionButton: SizedBox(
        height: 72,
        width: 72,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PresensiScreen(cameras: widget.cameras)),
            );
          },
          backgroundColor: const Color(0xFF6366F1),
          elevation: 4,
          shape: const CircleBorder(),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint, color: Colors.white, size: 36),
              Text("Absen",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ==========================================
      // BOTTOM NAVIGATION BAR
      // ==========================================
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Beranda', 0),
              _buildNavItem(Icons.explore_rounded, 'Eksplor', 1),

              const SizedBox(width: 48), // Ruang kosong untuk tombol absen tengah

              _buildNavItem(Icons.book_rounded, 'Logbook', 2),
              _buildNavItem(Icons.person_rounded, 'Profil', 3), // Tab Profil
            ],
          ),
        ),
      ),

      // ==========================================
      // MENAMPILKAN HALAMAN BERDASARKAN TAB
      // ==========================================
      body: _selectedIndex == 0
          ? _buildBeranda(context)
          : _selectedIndex == 2
              ? _buildLogbook()
              : _selectedIndex == 3
                  ? const ProfilScreen()
                  : const Center(child: Text("Fitur Segera Hadir")),
    );
  }

  // ==========================================
  // HALAMAN 1: BERANDA (Dashboard Utama)
  // ==========================================
  Widget _buildBeranda(BuildContext context) {
    // Mendengarkan perubahan data pengguna secara reaktif dari Provider
    final user = ref.watch(userProvider);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Stack(
          children: [
            // Background Ungu
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Column(
              children: [
                // Identitas Pengguna (Reaktif mengikuti data terbaru)
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFFE0E7FF),
                            child: Icon(Icons.person, color: Color(0xFF6366F1)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Halo, ${user.nama} 👋",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user.divisi,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_active_outlined,
                              color: Colors.white),
                          onPressed: () => _showComingSoon("Notifikasi"),
                        ),
                      ],
                    ),
                  ),
                ),

                // Kartu Informasi Status Kehadiran
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Status Kehadiran",
                                    style: TextStyle(
                                        color: Colors.black54, fontSize: 13)),
                                SizedBox(height: 4),
                                Text("Rabu, 28 Okt",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 14, color: Color(0xFF6366F1)),
                                  SizedBox(width: 4),
                                  Text("Kantor Pusat",
                                      style: TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  shape: BoxShape.circle),
                              child: Icon(Icons.info_outline,
                                  color: Colors.orange.shade400, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Anda belum melakukan absensi. Tekan tombol Absen di bawah.",
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Fitur Grid Menu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Fitur Magang",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
                children: [
                  _buildGridItem(
                      Icons.fingerprint, "Presensi", const Color(0xFF6366F1),
                      () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                PresensiScreen(cameras: widget.cameras)));
                  }),
                  _buildGridItem(Icons.edit_document, "Izin/Sakit", Colors.orange,
                      () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FormIzinScreen()));
                  }),
                  _buildGridItem(Icons.upload_file, "Tugas", Colors.blue, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FormTugasScreen()));
                  }),
                  _buildGridItem(Icons.assessment, "Nilai", Colors.green,
                      () => _showComingSoon("Rekap Nilai")),
                ],
              ),
            ],
          ),
        ),

        const Divider(thickness: 4, color: Color(0xFFF1F5F9)),

        // Kotak Pengumuman
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pengumuman Terbaru",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          shape: BoxShape.circle),
                      child:
                          const Icon(Icons.campaign, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Pengumpulan Laporan Akhir",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 4),
                          Text(
                              "Batas waktu pengumpulan laporan logbook minggu ini adalah hari Jumat pukul 17:00.",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ==========================================
  // HALAMAN 2: LOGBOOK (Tugas yang Dikerjakan)
  // ==========================================
  Widget _buildLogbook() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Logbook & Riwayat Tugas",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            "Daftar tugas divisi yang sudah Anda selesaikan.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),

          _buildTugasCard(
            judul: "Desain Poster Open Recruitment Batch 2",
            tanggal: "19 Okt 2026",
            nilai: "92",
            status: "Selesai Dinilai",
            warnaStatus: Colors.green,
          ),
          const SizedBox(height: 12),

          _buildTugasCard(
            judul: "Carousel Feed: 5 Tips Portofolio",
            tanggal: "20 Okt 2026",
            nilai: "90",
            status: "Selesai Dinilai",
            warnaStatus: Colors.green,
          ),
          const SizedBox(height: 12),

          _buildTugasCard(
            judul: "Pembuatan Form HTML & CSS",
            tanggal: "27 Okt 2026",
            nilai: "-",
            status: "Menunggu Penilaian",
            warnaStatus: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTugasCard({
    required String judul,
    required String tanggal,
    required String nilai,
    required String status,
    required Color warnaStatus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.assignment_turned_in,
                    color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text("Dikirim: $tanggal",
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: warnaStatus.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  nilai,
                  style: TextStyle(
                      color: warnaStatus,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              )
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: warnaStatus),
              const SizedBox(width: 6),
              Text(status,
                  style: TextStyle(
                      color: warnaStatus,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET BANTUAN (UI)
  // ==========================================
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        if (index == 0 || index == 2 || index == 3) {
          setState(() => _selectedIndex = index);
        } else {
          _showComingSoon(label);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade400,
              size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.black87,
                fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}