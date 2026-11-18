import 'package:flutter/material.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/admin/data/admin_repository.dart';
import 'package:apk_absensi/features/admin/widgets/admin_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class RekapPresensiScreen extends StatefulWidget {
  const RekapPresensiScreen({super.key});

  @override
  State<RekapPresensiScreen> createState() => _RekapPresensiScreenState();
}

class _RekapPresensiScreenState extends State<RekapPresensiScreen> {
  DateTime _tanggal = DateTime.now();
  int _tab = 0; // 0 = Semua, 1 = Masuk, 2 = Pulang, 3 = Belum hadir

  List<LogPresensi> _logs = [];
  List<ProfilAkun> _peserta = [];
  bool _memuat = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _error = null;
    });
    try {
      final hasil = await Future.wait([
        AdminRepository.presensiPadaTanggal(_tanggal),
        AdminRepository.daftarPeserta(),
      ]);
      if (!mounted) return;
      setState(() {
        _logs = hasil[0] as List<LogPresensi>;
        _peserta = hasil[1] as List<ProfilAkun>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = pesanError(e));
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  bool get _hariIni {
    final n = DateTime.now();
    return _tanggal.year == n.year &&
        _tanggal.month == n.month &&
        _tanggal.day == n.day;
  }

  void _geser(int hari) {
    final baru = _tanggal.add(Duration(days: hari));
    if (baru.isAfter(DateTime.now())) return;
    _tanggal = baru;
    _muat();
  }

  Future<void> _pilihTanggal() async {
    final t = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (t != null) {
      _tanggal = t;
      _muat();
    }
  }

  String _nama(String userId) {
    for (final p in _peserta) {
      if (p.id == userId) return p.nama;
    }
    return 'ID $userId';
  }

  @override
  Widget build(BuildContext context) {
    final masuk = _logs.where((l) => l.isMasuk).toList();
    final pulang = _logs.where((l) => !l.isMasuk).toList();
    final hadirIds = masuk.map((l) => l.userId).toSet();
    final belum = _peserta
        .where((p) => p.status == 'aktif' && !hadirIds.contains(p.id))
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _muat,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const PageHeader(
              label: 'Admin',
              title: 'Rekap presensi',
              subtitle: 'Pantau kehadiran peserta per hari.',
            ),
            // Pemilih tanggal
            RCard(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _geser(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pilihTanggal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Text(_hariIni ? 'Hari ini' : '${_tanggal.year}',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.muted)),
                            Text(tanggalId(_tanggal),
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _hariIni ? null : () => _geser(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Angka('Masuk', masuk.length, AppColors.green),
                const SizedBox(width: 10),
                _Angka('Pulang', pulang.length, AppColors.ink),
                const SizedBox(width: 10),
                _Angka('Belum', belum.length, AppColors.coral),
              ],
            ),
            const SizedBox(height: 16),
            Segmented(
              items: const ['Semua', 'Masuk', 'Pulang', 'Belum'],
              index: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 16),
            if (_memuat)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.green)),
              )
            else if (_error != null)
              InfoKosong(
                icon: Icons.cloud_off_rounded,
                judul: 'Gagal memuat presensi',
                pesan: _error,
                onCobaLagi: _muat,
              )
            else if (_tab == 3)
              ..._daftarBelum(belum)
            else
              ..._daftarLog([_logs, masuk, pulang][_tab]),
          ],
        ),
      ),
    );
  }

  List<Widget> _daftarLog(List<LogPresensi> logs) {
    if (logs.isEmpty) {
      return const [
        InfoKosong(
          icon: Icons.event_busy_rounded,
          judul: 'Tidak ada data',
          pesan: 'Belum ada presensi untuk filter ini.',
        ),
      ];
    }
    return [
      for (final l in logs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: KartuLog(log: l, judul: _nama(l.userId)),
        ),
    ];
  }

  List<Widget> _daftarBelum(List<ProfilAkun> belum) {
    if (belum.isEmpty) {
      return const [
        InfoKosong(
          icon: Icons.celebration_rounded,
          judul: 'Semua peserta aktif sudah hadir',
        ),
      ];
    }
    return [
      for (final p in belum)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Avatar(p.nama, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nama,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                      Text(p.divisi ?? '@${p.username}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                ),
                const StatusChip('Belum hadir',
                    fg: AppColors.coral, bg: AppColors.coralSoft),
              ],
            ),
          ),
        ),
    ];
  }
}

class _Angka extends StatelessWidget {
  const _Angka(this.label, this.nilai, this.warna);

  final String label;
  final int nilai;
  final Color warna;

  @override
  Widget build(BuildContext context) => Expanded(
        child: RCard(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$nilai',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: warna)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
      );
}

/// Kartu satu log presensi (dipakai juga di Detail Peserta).
class KartuLog extends StatelessWidget {
  const KartuLog({super.key, required this.log, required this.judul});

  final LogPresensi log;
  final String judul;

  void _bukaDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('${log.tipe} · ${tanggalId(log.waktu)}, ${log.jam}',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 16),
              if (log.fotoUrl != null && log.fotoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      log.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.line,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppColors.muted),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Text('Ketepatan: ${log.statusKetepatan}',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: log.isTerlambat ? AppColors.coral : AppColors.ink)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Text('Biometrik: ${log.biometricStatus ?? '-'}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.ink)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(log.isWfh ? Icons.home_work_outlined : Icons.business_outlined,
                      size: 18, color: log.isWfh ? const Color(0xFF2B6CB0) : AppColors.muted),
                  const SizedBox(width: 8),
                  Text(
                    log.isWfh ? 'Tipe Kerja: WFH (Work From Home)' : 'Tipe Kerja: WFO (Kantor)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: log.isWfh ? FontWeight.bold : FontWeight.normal,
                      color: log.isWfh ? const Color(0xFF2B6CB0) : AppColors.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.latitude == null
                          ? 'Lokasi tidak tersedia'
                          : '${log.latitude!.toStringAsFixed(6)}, ${log.longitude!.toStringAsFixed(6)}',
                      style:
                          const TextStyle(fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
              if (log.keterangan != null && log.keterangan!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: log.isTerlambat
                        ? AppColors.coralSoft
                        : (log.isPulangAwal
                            ? const Color(0xFFFFF4E5)
                            : AppColors.bg),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: log.isTerlambat
                          ? const Color(0xFFF3CFC5)
                          : (log.isPulangAwal
                              ? const Color(0xFFFFD8A8)
                              : AppColors.line),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: log.isTerlambat
                                ? AppColors.coral
                                : (log.isPulangAwal
                                    ? const Color(0xFFE8590C)
                                    : AppColors.green),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            log.isTerlambat
                                ? 'Alasan Keterlambatan'
                                : (log.isPulangAwal
                                    ? 'Alasan Pulang Lebih Awal'
                                    : 'Keterangan Presensi'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: log.isTerlambat
                                  ? AppColors.coral
                                  : (log.isPulangAwal
                                      ? const Color(0xFFE8590C)
                                      : AppColors.green),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.keterangan!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adaFoto = log.fotoUrl != null && log.fotoUrl!.isNotEmpty;

    return RCard(
      onTap: () => _bukaDetail(context),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: adaFoto
                  ? Image.network(
                      log.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const IconBubble(
                          Icons.person_outline_rounded,
                          size: 48),
                    )
                  : const IconBubble(Icons.person_outline_rounded, size: 48),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('Pukul ${log.jam} WIB · ${log.statusKetepatan}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: (log.isTerlambat || log.isPulangAwal)
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: log.isTerlambat
                            ? AppColors.coral
                            : (log.isPulangAwal ? const Color(0xFFE8590C) : AppColors.muted))),
                if (log.keterangan != null && log.keterangan!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Alasan: "${log.keterangan}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: log.isTerlambat
                          ? AppColors.coral
                          : (log.isPulangAwal ? const Color(0xFFE8590C) : AppColors.muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusChip(
                log.isMasuk
                    ? (log.isTerlambat ? 'Terlambat' : 'Tepat Waktu')
                    : (log.isPulangAwal ? 'Pulang Awal' : 'Pulang'),
                fg: log.isMasuk
                    ? (log.isTerlambat ? AppColors.coral : AppColors.green)
                    : (log.isPulangAwal ? const Color(0xFFC2410C) : AppColors.ink),
                bg: log.isMasuk
                    ? (log.isTerlambat ? AppColors.coralSoft : AppColors.greenSoft)
                    : (log.isPulangAwal ? const Color(0xFFFFF7ED) : const Color(0xFFEBE6D9)),
              ),
              if (log.isWfh) ...[
                const SizedBox(height: 4),
                const StatusChip(
                  'WFH',
                  fg: Color(0xFF2B6CB0),
                  bg: Color(0xFFEBF8FF),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

