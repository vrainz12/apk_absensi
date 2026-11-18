import 'package:flutter/material.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/admin/data/admin_repository.dart';
import 'package:apk_absensi/features/admin/widgets/admin_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class AdminBerandaScreen extends StatefulWidget {
  const AdminBerandaScreen({
    super.key,
    required this.profil,
    required this.onTab,
  });

  final ProfilAkun profil;
  final ValueChanged<int> onTab;

  @override
  State<AdminBerandaScreen> createState() => _AdminBerandaScreenState();
}

class _AdminBerandaScreenState extends State<AdminBerandaScreen> {
  late Future<RingkasanAdmin> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminRepository.ringkasan();
  }

  Future<void> _muatUlang() async {
    final f = AdminRepository.ringkasan();
    setState(() => _future = f);
    await f.catchError((_) => const RingkasanAdmin(
        totalPeserta: 0,
        pesertaAktif: 0,
        hadirHariIni: 0,
        sudahPulang: 0,
        logTerbaru: []));
  }

  String get _sapaan {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final namaDepan = widget.profil.nama.split(' ').first;

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _muatUlang,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: PageHeader(
                    label: 'Admin · ${tanggalId(DateTime.now())}',
                    title: '$_sapaan,\n$namaDepan.',
                  ),
                ),
                Avatar(widget.profil.nama, size: 48),
              ],
            ),
            FutureBuilder<RingkasanAdmin>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.green)),
                  );
                }
                if (snap.hasError) {
                  return InfoKosong(
                    icon: Icons.cloud_off_rounded,
                    judul: 'Gagal memuat ringkasan',
                    pesan: pesanError(snap.error!),
                    onCobaLagi: _muatUlang,
                  );
                }
                return _isi(snap.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _isi(RingkasanAdmin r) {
    final persen =
        r.pesertaAktif == 0 ? 0.0 : r.hadirHariIni / r.pesertaAktif;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kartu kehadiran hari ini
        RCard(
          color: AppColors.green,
          borderColor: AppColors.green,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kehadiran hari ini',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${r.hadirHariIni}',
                      style: const TextStyle(
                          fontSize: 40,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 4),
                    child: Text('/ ${r.pesertaAktif} peserta aktif',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white70)),
                  ),
                  const Spacer(),
                  Text('${(persen * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
              const SizedBox(height: 14),
              RProgress(persen,
                  color: AppColors.coral,
                  track: Colors.white.withValues(alpha: 0.18)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(
                icon: Icons.groups_rounded,
                nilai: '${r.totalPeserta}',
                label: 'Total peserta',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                icon: Icons.logout_rounded,
                nilai: '${r.sudahPulang}',
                label: 'Sudah pulang',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                icon: Icons.hourglass_empty_rounded,
                nilai: '${r.belumHadir}',
                label: 'Belum hadir',
                bg: AppColors.coralSoft,
                fg: AppColors.coral,
              ),
            ),
          ],
        ),
        const SectionTitle('Perlu Ditinjau'),
        Row(
          children: [
            Expanded(
              child: _PerluReviewCard(
                icon: Icons.healing_rounded,
                judul: 'Izin Menunggu',
                jumlah: r.izinMenunggu,
                keterangan: r.izinMenunggu > 0 ? 'Permohonan perlu ACC' : 'Semua sudah ditinjau',
                bgBadge: r.izinMenunggu > 0 ? AppColors.coralSoft : AppColors.greenSoft,
                fgBadge: r.izinMenunggu > 0 ? AppColors.coral : AppColors.green,
                onTap: () => widget.onTab(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PerluReviewCard(
                icon: Icons.assignment_turned_in_rounded,
                judul: 'Tugas Masuk',
                jumlah: r.tugasBelumDinilai,
                keterangan: r.tugasBelumDinilai > 0 ? 'Belum dinilai' : 'Semua telah dinilai',
                bgBadge: r.tugasBelumDinilai > 0 ? const Color(0xFFFBF0D8) : AppColors.greenSoft,
                fgBadge: r.tugasBelumDinilai > 0 ? const Color(0xFF946200) : AppColors.green,
                onTap: () => widget.onTab(3),
              ),
            ),
          ],
        ),
        const SectionTitle('Menu cepat'),
        Row(
          children: [
            Expanded(
              child: _Menu(
                icon: Icons.person_add_alt_1_rounded,
                label: 'Kelola\npeserta',
                onTap: () => widget.onTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Menu(
                icon: Icons.fact_check_rounded,
                label: 'Rekap\npresensi',
                onTap: () => widget.onTab(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Menu(
                icon: Icons.rate_review_rounded,
                label: 'Izin &\npenilaian',
                onTap: () => widget.onTab(3),
              ),
            ),
          ],
        ),
        SectionTitle('Aktivitas terbaru',
            action: 'Lihat semua', onAction: () => widget.onTab(2)),
        if (r.logTerbaru.isEmpty)
          const RCard(
            child: InfoKosong(
              icon: Icons.event_busy_rounded,
              judul: 'Belum ada presensi hari ini',
            ),
          )
        else
          RCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < r.logTerbaru.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _BarisLog(r.logTerbaru[i],
                      nama: r.namaUntuk(r.logTerbaru[i].userId)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.nilai,
    required this.label,
    this.bg = AppColors.greenSoft,
    this.fg = AppColors.green,
  });

  final IconData icon;
  final String nilai;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => RCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBubble(icon, bg: bg, fg: fg, size: 34),
            const SizedBox(height: 10),
            Text(nilai,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
        ),
      );
}

class _PerluReviewCard extends StatelessWidget {
  const _PerluReviewCard({
    required this.icon,
    required this.judul,
    required this.jumlah,
    required this.keterangan,
    required this.bgBadge,
    required this.fgBadge,
    required this.onTap,
  });

  final IconData icon;
  final String judul;
  final int jumlah;
  final String keterangan;
  final Color bgBadge;
  final Color fgBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconBubble(icon, size: 36),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: bgBadge, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '$jumlah',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: fgBadge),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              judul,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
            ),
            const SizedBox(height: 2),
            Text(
              keterangan,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      );
}

class _Menu extends StatelessWidget {
  const _Menu({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBubble(icon, size: 40),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      );
}

class _BarisLog extends StatelessWidget {
  const _BarisLog(this.log, {required this.nama});
  final LogPresensi log;
  final String nama;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            IconBubble(
              log.isMasuk ? Icons.login_rounded : Icons.logout_rounded,
              size: 36,
              bg: log.isMasuk ? AppColors.greenSoft : AppColors.coralSoft,
              fg: log.isMasuk ? AppColors.green : AppColors.coral,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
            ),
            Text('${log.tipe} · ${log.jam}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      );
}
