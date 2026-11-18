import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/presensi/data/statistik_kehadiran_service.dart';
import 'package:apk_absensi/features/profil/user/user_provider.dart';

class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({
    super.key,
    required this.onTab,
    required this.onAbsen,
    required this.onIzin,
    required this.onNilai,
    required this.onTugas,
    this.jamMasuk,
    this.jamPulang,
    this.statistik = StatistikKehadiran.kosong,
    this.jumlahNotif = 0,
    this.onBukaNotifikasi,
    this.onRefresh,
  });

  /// Jam presensi hari ini (null = belum presensi).
  final String? jamMasuk;
  final String? jamPulang;
  final StatistikKehadiran statistik;
  final int jumlahNotif;
  final VoidCallback? onBukaNotifikasi;
  final Future<void> Function()? onRefresh;
  final ValueChanged<int> onTab;
  final VoidCallback onAbsen;
  final VoidCallback onIzin;
  final VoidCallback onNilai;
  final VoidCallback onTugas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final nama = user.nama.trim();
    final panggilan = nama.isEmpty ? '' : ' ${nama.split(' ').last}';

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: onRefresh ?? () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.spa_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('ruang magang',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.ink)),
              const Spacer(),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    onPressed: onBukaNotifikasi,
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.ink),
                  ),
                  if (jumlahNotif > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          jumlahNotif > 9 ? '9+' : '$jumlahNotif',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          PageHeader(
            label: tanggalId(DateTime.now()),
            title: 'Pagi,$panggilan.\nSiap bertumbuh?',
          ),

          // 1. BANNER PENGINGAT OTOMATIS (PUSH IN-APP)
          Builder(
            builder: (context) {
              final now = DateTime.now();
              final totalMenit = now.hour * 60 + now.minute;
              final butuhMasuk = jamMasuk == null && totalMenit >= 7 * 60 && totalMenit <= 12 * 60;
              final butuhPulang = jamMasuk != null && jamPulang == null && totalMenit >= 16 * 60 && totalMenit <= 18 * 60;

              if (butuhMasuk) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RCard(
                    color: AppColors.coralSoft,
                    borderColor: const Color(0xFFF3CFC5),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const IconBubble(Icons.warning_amber_rounded,
                            bg: Colors.white, fg: AppColors.coral, size: 36),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pengingat Presensi Datang',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.ink)),
                              SizedBox(height: 2),
                              Text(
                                  'Kamu belum absen masuk hari ini. Batas waktu pukul 09:00 WIB agar tidak terlambat.',
                                  style: TextStyle(
                                      fontSize: 11.5, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onAbsen,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.coral,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Presensi',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (butuhPulang) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: RCard(
                    color: const Color(0xFFFFF4E5),
                    borderColor: const Color(0xFFFFD8A8),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const IconBubble(Icons.schedule_rounded,
                            bg: Colors.white, fg: Color(0xFFE8590C), size: 36),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pengingat Presensi Pulang',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.ink)),
                              SizedBox(height: 2),
                              Text(
                                  'Jam kerja selesai pukul 16:00. Segera lakukan presensi pulang sebelum pukul 17:00 WIB.',
                                  style: TextStyle(
                                      fontSize: 11.5, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onAbsen,
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE8590C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Pulang',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // 2. KARTU PRESENSI HARI INI
          RCard(
            color: AppColors.green,
            borderColor: AppColors.green,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Presensi hari ini (Jam Kerja 09:00–16:00)',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                const SizedBox(height: 6),
                const Text('09:00–16:00',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8)),
                const SizedBox(height: 10),
                if (jamMasuk == null) ...[
                  const StatusChip('Belum presensi masuk',
                      fg: Colors.white, bg: AppColors.coral),
                  const SizedBox(height: 18),
                  PillButton(
                    label: 'Isi presensi sekarang',
                    icon: Icons.fingerprint,
                    background: AppColors.bg,
                    foreground: AppColors.green,
                    onPressed: onAbsen,
                  ),
                ] else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusChip('Masuk: $jamMasuk WIB',
                          fg: AppColors.green, bg: AppColors.greenSoft),
                      if (jamPulang != null)
                        StatusChip('Pulang: $jamPulang WIB',
                            fg: AppColors.ink, bg: const Color(0xFFEBE6D9))
                      else
                        const StatusChip('Belum presensi pulang',
                            fg: Color(0xFF946200), bg: Color(0xFFFBF0D8)),
                    ],
                  ),
                  if (jamPulang == null) ...[
                    const SizedBox(height: 14),
                    PillButton(
                      label: 'Presensi pulang sekarang',
                      icon: Icons.logout_rounded,
                      background: AppColors.bg,
                      foreground: AppColors.green,
                      onPressed: onAbsen,
                    ),
                  ],
                ],
              ],
            ),
          ),

          // 3. AKUMULASI STATISTIK KEHADIRAN PESERTA
          const SectionTitle('Akumulasi Kehadiran'),
          RCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              children: [
                _StatBox(
                  label: 'Hadir',
                  nilai: '${statistik.totalHadir}',
                  satuan: 'hari',
                  warna: AppColors.green,
                  icon: Icons.check_circle_outline_rounded,
                ),
                Container(width: 1, height: 42, color: AppColors.line),
                _StatBox(
                  label: 'Izin/Sakit',
                  nilai: '${statistik.totalIzinSakit}',
                  satuan: 'hari',
                  warna: const Color(0xFF2B6CB0),
                  icon: Icons.event_note_outlined,
                ),
                Container(width: 1, height: 42, color: AppColors.line),
                _StatBox(
                  label: 'Terlambat',
                  nilai: '${statistik.totalTerlambat}',
                  satuan: statistik.totalMenitTerlambat > 0 ? '${statistik.totalMenitTerlambat}m' : 'kali',
                  warna: AppColors.coral,
                  icon: Icons.access_time_rounded,
                ),
              ],
            ),
          ),

          const SectionTitle('Menu cepat'),
          Row(
            children: [
              _Quick(Icons.fingerprint, 'Presensi', () => onTab(2)),
              _Quick(Icons.edit_note_rounded, 'Izin', onIzin),
              _Quick(Icons.task_alt_rounded, 'Tugas', onTugas),
              _Quick(Icons.insights_rounded, 'Nilai', onNilai),
              _Quick(Icons.menu_book_rounded, 'Logbook', () => onTab(3)),
            ],
          ),

          const SectionTitle('Fokus hari ini'),
          const RCard(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _AgendaRow('10:00', 'Review dashboard admin', 'Ruang rapat • Web Development'),
                Divider(height: 1, color: AppColors.line),
                _AgendaRow('13:00', 'Standup mingguan', 'Online • 15 menit'),
                Divider(height: 1, color: AppColors.line),
                _AgendaRow('16:30', 'Isi logbook harian', 'Tenggat hari ini'),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const RCard(
            color: AppColors.coralSoft,
            borderColor: Color(0xFFF3CFC5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBubble(Icons.campaign_rounded,
                    bg: Colors.white, fg: AppColors.coral, size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pengumpulan laporan akhir',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.ink)),
                      SizedBox(height: 4),
                      Text(
                          'Batas pengumpulan logbook minggu ini hari Jumat pukul 17:00.',
                          style: TextStyle(
                              fontSize: 12.5, height: 1.4, color: AppColors.ink)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _Quick extends StatelessWidget {
  const _Quick(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            IconBubble(icon, size: 52),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow(this.time, this.title, this.sub);

  final String time;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(time,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.green)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.nilai,
    required this.satuan,
    required this.warna,
    required this.icon,
  });

  final String label;
  final String nilai;
  final String satuan;
  final Color warna;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: warna),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                nilai,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: warna,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                satuan,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
