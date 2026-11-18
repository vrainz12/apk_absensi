import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apk_absensi/core/constants/magang_constants.dart';
import 'package:apk_absensi/core/services/notification_service.dart';
import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';
import 'package:apk_absensi/features/presensi/data/statistik_kehadiran_service.dart';
import 'package:apk_absensi/features/presensi/tugas/form_tugas_screen.dart';
import 'package:apk_absensi/features/shell/screens/beranda_screen.dart';
import 'package:apk_absensi/features/shell/screens/izin_sakit_screen.dart';
import 'package:apk_absensi/features/shell/screens/logbook_tab.dart';
import 'package:apk_absensi/features/shell/screens/nilai_screen.dart';
import 'package:apk_absensi/features/shell/screens/presensi_tab.dart';
import 'package:apk_absensi/features/shell/screens/profil_tab.dart';

enum _TipeNotif { tugas, izin, logbook }

class _ItemNotifikasi {
  final String id;
  final _TipeNotif tipe;
  final String judul;
  final String pesan;
  final String status;
  final DateTime waktu;

  const _ItemNotifikasi({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.pesan,
    required this.status,
    required this.waktu,
  });
}

/// Pengganti DashboardScreen: 5 tab (Beranda, Eksplor, Presensi, Logbook, Profil).
/// Izin/Sakit, Nilai, dan Tugas dibuka dari menu cepat di Beranda.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Jam presensi pertama hari ini (mis. "10:39"), null jika belum presensi.
  String? _jamMasuk;

  /// Jam presensi terakhir/pulang hari ini.
  String? _jamPulang;

  /// Daftar notifikasi / balasan evaluasi dari admin.
  List<_ItemNotifikasi> _notifikasi = [];

  /// Jumlah notifikasi yang belum dibuka/dibaca
  int _jumlahBelumDibaca = 0;

  /// Waktu terakhir membuka daftar notifikasi
  DateTime? _terakhirDibacaWaktu;

  /// Akumulasi performa kehadiran peserta
  StatistikKehadiran _statistik = StatistikKehadiran.kosong;

  @override
  void initState() {
    super.initState();
    _muatStatusPresensi();
    _muatNotifikasi();
    _muatStatistik();
  }

  Future<void> _muatStatistik() async {
    try {
      final res = await StatistikKehadiranService.ambilStatistik(AuthService.userId);
      if (mounted) {
        setState(() => _statistik = res);
      }
    } catch (_) {}
  }

  Future<void> _muatNotifikasi() async {
    try {
      final uid = AuthService.userId;
      final db = Supabase.instance.client;

      final hasil = await Future.wait([
        // Tugas yang sudah dinilai atau revisi
        db
            .from('pengumpulan_tugas')
            .select()
            .eq('user_id', uid)
            .neq('status', 'menunggu')
            .order('created_at', ascending: false)
            .limit(10),
        // Izin yang sudah disetujui atau ditolak
        db
            .from('pengajuan_izin')
            .select()
            .eq('user_id', uid)
            .neq('status', 'menunggu')
            .order('created_at', ascending: false)
            .limit(10),
        // Logbook yang sudah disetujui
        db
            .from('logbook_harian')
            .select()
            .eq('user_id', uid)
            .eq('status', 'disetujui')
            .order('updated_at', ascending: false)
            .limit(10),
      ]);

      final List<_ItemNotifikasi> list = [];

      // 1. Notifikasi Tugas
      for (final r in (hasil[0] as List)) {
        final st = r['status']?.toString().toLowerCase() ?? '';
        final nilai = r['nilai'];
        final catatan = r['catatan_penilai']?.toString() ?? '';
        final judulTugas = r['judul']?.toString() ?? 'Tugas Magang';

        list.add(_ItemNotifikasi(
          id: r['id']?.toString() ?? '',
          tipe: _TipeNotif.tugas,
          judul: 'Tugas: $judulTugas',
          pesan: nilai != null
              ? 'Nilai: $nilai/100${catatan.isNotEmpty ? " · Evaluasi: \"$catatan\"" : ""}'
              : (catatan.isNotEmpty ? 'Catatan: "$catatan"' : 'Status tugas: $st'),
          status: st == 'dinilai' ? 'Dinilai' : 'Revisi',
          waktu: DateTime.tryParse(r['dinilai_at']?.toString() ?? '')?.toLocal() ??
              DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
        ));
      }

      // 2. Notifikasi Izin
      for (final r in (hasil[1] as List)) {
        final st = r['status']?.toString().toLowerCase() ?? '';
        final jenis = r['jenis']?.toString() ?? 'Izin';
        final catatan = r['catatan_admin']?.toString() ?? '';

        list.add(_ItemNotifikasi(
          id: r['id']?.toString() ?? '',
          tipe: _TipeNotif.izin,
          judul: 'Pengajuan $jenis: ${st == "disetujui" ? "Disetujui" : "Ditolak"}',
          pesan: catatan.isNotEmpty
              ? 'Catatan admin: "$catatan"'
              : 'Permohonan $jenis Anda telah di-$st oleh admin.',
          status: st == 'disetujui' ? 'Disetujui' : 'Ditolak',
          waktu: DateTime.tryParse(r['created_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
        ));
      }

      // 3. Notifikasi Logbook
      for (final r in (hasil[2] as List)) {
        final tgl = r['tanggal']?.toString() ?? '';
        final catatan = r['catatan_admin']?.toString() ?? '';

        list.add(_ItemNotifikasi(
          id: r['id']?.toString() ?? '',
          tipe: _TipeNotif.logbook,
          judul: 'Logbook $tgl Disetujui',
          pesan: catatan.isNotEmpty
              ? 'Catatan admin: "$catatan"'
              : 'Logbook harian Anda telah diverifikasi oleh admin.',
          status: 'Disetujui',
          waktu: DateTime.tryParse(r['updated_at']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
        ));
      }

      list.sort((a, b) => b.waktu.compareTo(a.waktu));

      final prefs = await SharedPreferences.getInstance();
      final terakhirDibacaStr = prefs.getString('notif_terakhir_dibaca');
      final terakhirDibaca = terakhirDibacaStr != null
          ? DateTime.tryParse(terakhirDibacaStr)
          : null;

      final belumDibaca = list
          .where((n) => terakhirDibaca == null || n.waktu.isAfter(terakhirDibaca))
          .length;

      if (mounted) {
        setState(() {
          _notifikasi = list;
          _jumlahBelumDibaca = belumDibaca;
          _terakhirDibacaWaktu = terakhirDibaca;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat notifikasi balasan admin: $e');
    }
  }

  Future<void> _bukaDaftarNotifikasi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notif_terakhir_dibaca', DateTime.now().toIso8601String());
    if (mounted) {
      setState(() {
        _jumlahBelumDibaca = 0;
      });
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: AppColors.green, size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Notifikasi & Balasan Admin',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (_notifikasi.isNotEmpty)
                  StatusChip(
                    '${_notifikasi.length} respon',
                    bg: AppColors.greenSoft,
                    fg: AppColors.green,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _notifikasi.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_email_read_outlined,
                              size: 48, color: AppColors.muted),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada balasan dari admin',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Saat admin menilai tugas, merespon izin, atau menyetujui logbook harian, pemberitahuan akan muncul di sini.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 12.5, color: AppColors.muted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _notifikasi.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = _notifikasi[i];
                        IconData icon;
                        Color iconBg;
                        Color iconFg;
                        VoidCallback? aksi;

                        switch (n.tipe) {
                          case _TipeNotif.tugas:
                            icon = Icons.assignment_turned_in_rounded;
                            iconBg = n.status == 'Dinilai'
                                ? AppColors.greenSoft
                                : AppColors.coralSoft;
                            iconFg = n.status == 'Dinilai'
                                ? AppColors.green
                                : AppColors.coral;
                            aksi = () {
                              Navigator.pop(ctx);
                              _push(const NilaiScreen());
                            };
                            break;
                          case _TipeNotif.izin:
                            icon = Icons.event_note_rounded;
                            iconBg = n.status == 'Disetujui'
                                ? AppColors.greenSoft
                                : AppColors.coralSoft;
                            iconFg = n.status == 'Disetujui'
                                ? AppColors.green
                                : AppColors.coral;
                            aksi = () {
                              Navigator.pop(ctx);
                              _push(const IzinSakitScreen());
                            };
                            break;
                          case _TipeNotif.logbook:
                            icon = Icons.verified_rounded;
                            iconBg = AppColors.greenSoft;
                            iconFg = AppColors.green;
                            aksi = () {
                              Navigator.pop(ctx);
                              setState(() => _index = 3); // Tab Logbook
                            };
                            break;
                        }

                        return InkWell(
                          onTap: aksi,
                          borderRadius: BorderRadius.circular(16),
                          child: RCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconBubble(icon,
                                    bg: iconBg, fg: iconFg, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n.judul,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          if (_terakhirDibacaWaktu != null &&
                                              n.waktu.isAfter(_terakhirDibacaWaktu!)) ...[
                                            const StatusChip(
                                              'BARU',
                                              bg: AppColors.coralSoft,
                                              fg: AppColors.coral,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          StatusChip(
                                            n.status,
                                            bg: iconBg,
                                            fg: iconFg,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.pesan,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          height: 1.35,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        tanggalId(n.waktu),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.muted, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _muatStatusPresensi() async {
    try {
      final now = DateTime.now();
      final awalHariLokal = DateTime(now.year, now.month, now.day);
      final awalHariUtc = awalHariLokal.toUtc().toIso8601String();

      // Ambil SEMUA log presensi hari ini untuk user tersebut
      final rows = await Supabase.instance.client
          .from('presensi_logs')
          .select('timestamp, tipe_absen')
          .eq('user_id', AuthService.userId)
          .gte('timestamp', awalHariUtc)
          .order('timestamp', ascending: true);

      String? jamMasuk;
      String? jamPulang;

      for (var row in rows) {
        final timestampStr = row['timestamp']?.toString() ?? '';
        final tipe = row['tipe_absen']?.toString().toLowerCase() ?? '';

        // Konversi ke zona waktu lokal (WIB) secara presisi dengan koreksi offset
        final dt = MagangConstants.parseWaktuPresensi(timestampStr);
        final jamMenit = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

        if (tipe.contains('masuk')) {
          jamMasuk ??= jamMenit;
        } else if (tipe.contains('pulang')) {
          jamPulang = jamMenit;
        } else {
          if (jamMasuk == null) {
            jamMasuk = jamMenit;
          } else {
            jamPulang = jamMenit;
          }
        }
      }

      if (mounted) {
        setState(() {
          _jamMasuk = jamMasuk;
          _jamPulang = jamPulang;
        });

        // Trigger push notification pengingat jika belum presensi datang / pulang
        NotificationService.instance.cekDanKirimPengingatPresensi(
          jamMasuk: jamMasuk,
          jamPulang: jamPulang,
        );
      }
    } catch (e) {
      debugPrint('Gagal memuat status presensi: $e');
    }
  }

  Future<void> _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  // Dipanggil PresensiTab setelah presensi berhasil, untuk menyegarkan status.
  Future<void> _absen() async {
    await _muatStatusPresensi();
    await _muatStatistik();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            BerandaScreen(
              jamMasuk: _jamMasuk,
              jamPulang: _jamPulang,
              jumlahNotif: _jumlahBelumDibaca,
              statistik: _statistik,
              onRefresh: () async {
                await _muatStatusPresensi();
                await _muatNotifikasi();
                await _muatStatistik();
              },
              onBukaNotifikasi: _bukaDaftarNotifikasi,
              onTab: (i) => setState(() => _index = i),
              onAbsen: () => setState(() => _index = 2), // tab Presensi
              onIzin: () => _push(const IzinSakitScreen()).then((_) {
                _muatNotifikasi();
                _muatStatistik();
              }),
              onNilai: () => _push(const NilaiScreen()).then((_) => _muatNotifikasi()),
              onTugas: () => _push(const FormTugasScreen()).then((_) => _muatNotifikasi()),
            ),

            EksplorTab(
              onTabSelected: (i) => setState(() => _index = i),
            ),

            // Kamera & GPS hanya hidup saat tab Presensi (index 2) dibuka.
            _index == 2
                ? PresensiTab(
                    onAbsen: _absen,
                    onBack: () => setState(() => _index = 0),
                    jamMasuk: _jamMasuk,
                    jamPulang: _jamPulang,
                  )
                : const SizedBox.shrink(),

            const LogbookTab(),
            const ProfilTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.search_rounded),
                selectedIcon: Icon(Icons.search_rounded),
                label: 'Eksplor'),
            NavigationDestination(
                icon: Icon(Icons.fingerprint),
                selectedIcon: Icon(Icons.fingerprint),
                label: 'Presensi'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Logbook'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// WIDGET EKSPLOR TAB (PENCARIAN FITUR)
// ======================================================================
class EksplorTab extends StatefulWidget {
  final ValueChanged<int> onTabSelected;

  const EksplorTab({super.key, required this.onTabSelected});

  @override
  State<EksplorTab> createState() => _EksplorTabState();
}

class _EksplorTabState extends State<EksplorTab> {
  List<Map<String, dynamic>> _semuaData = [];
  List<Map<String, dynamic>> _hasilPencarian = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _semuaData = [
      {'judul': 'Isi Form Tugas Divisi', 'kategori': 'Tugas', 'icon': Icons.task_alt_rounded, 'aksi': 'push_tugas'},
      {'judul': 'Isi Logbook Harian', 'kategori': 'Logbook', 'icon': Icons.menu_book_rounded, 'aksi': 'tab_logbook'},
      {'judul': 'Lakukan Presensi / Absen', 'kategori': 'Kehadiran', 'icon': Icons.fingerprint_rounded, 'aksi': 'tab_presensi'},
      {'judul': 'Ajukan Izin atau Sakit', 'kategori': 'Kehadiran', 'icon': Icons.edit_document, 'aksi': 'push_izin'},
      {'judul': 'Lihat Daftar Nilai', 'kategori': 'Evaluasi', 'icon': Icons.auto_graph, 'aksi': 'push_nilai'},
      {'judul': 'Buka Halaman Profil', 'kategori': 'Pengaturan', 'icon': Icons.person_rounded, 'aksi': 'tab_profil'},
      {'judul': 'Kembali ke Beranda', 'kategori': 'Dashboard', 'icon': Icons.home_rounded, 'aksi': 'tab_beranda'},
    ];

    _hasilPencarian = _semuaData;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _lakukanPencarian(String query) {
    setState(() {
      if (query.isEmpty) {
        _hasilPencarian = _semuaData;
      } else {
        _hasilPencarian = _semuaData.where((item) {
          final judul = item['judul'].toString().toLowerCase();
          final kategori = item['kategori'].toString().toLowerCase();
          final input = query.toLowerCase();
          return judul.contains(input) || kategori.contains(input);
        }).toList();
      }
    });
  }

  void _jalankanAksi(String aksi) {
    FocusScope.of(context).unfocus();

    switch (aksi) {
      case 'push_tugas':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FormTugasScreen()));
        break;
      case 'push_izin':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const IzinSakitScreen()));
        break;
      case 'push_nilai':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NilaiScreen()));
        break;
      case 'tab_beranda':
        widget.onTabSelected(0);
        break;
      case 'tab_presensi':
        widget.onTabSelected(2);
        break;
      case 'tab_logbook':
        widget.onTabSelected(3);
        break;
      case 'tab_profil':
        widget.onTabSelected(4);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eksplor Fitur',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1B4332)),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _searchController,
              onChanged: _lakukanPencarian,
              decoration: InputDecoration(
                hintText: 'Cari Tugas, Logbook, Izin...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _lakukanPencarian('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: _hasilPencarian.isEmpty
                  ? const Center(
                      child: Text('Fitur tidak ditemukan.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    )
                  : ListView.builder(
                      itemCount: _hasilPencarian.length,
                      itemBuilder: (context, index) {
                        final item = _hasilPencarian[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: InkWell(
                            onTap: () => _jalankanAksi(item['aksi'].toString()),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F2EC),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(item['icon'] as IconData, color: const Color(0xFF1B4332), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['judul'].toString(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B4332)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['kategori'].toString(),
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}