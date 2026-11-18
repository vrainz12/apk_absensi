import 'package:flutter/material.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/admin/data/admin_repository.dart';
import 'package:apk_absensi/features/admin/screens/rekap_presensi_screen.dart';
import 'package:apk_absensi/features/admin/widgets/admin_widgets.dart';
import 'package:apk_absensi/features/admin/widgets/form_peserta_sheet.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class DetailPesertaScreen extends StatefulWidget {
  const DetailPesertaScreen({super.key, required this.peserta});

  final ProfilAkun peserta;

  @override
  State<DetailPesertaScreen> createState() => _DetailPesertaScreenState();
}

class _DetailPesertaScreenState extends State<DetailPesertaScreen> {
  late ProfilAkun _p = widget.peserta;
  late Future<List<LogPresensi>> _riwayat;
  bool _berubah = false;
  bool _sibuk = false;

  @override
  void initState() {
    super.initState();
    _riwayat = AdminRepository.presensiPeserta(_p.id);
  }

  Future<void> _segarkanProfil() async {
    final baru = await AdminRepository.ambilPeserta(_p.id);
    if (baru != null && mounted) setState(() => _p = baru);
  }

  Future<void> _ubah() async {
    final ok = await showFormPeserta(context, peserta: _p);
    if (ok == true) {
      _berubah = true;
      await _segarkanProfil();
    }
  }

  Future<void> _gantiStatus(String status) async {
    if (status == _p.status) return;
    setState(() => _sibuk = true);
    try {
      await AdminRepository.ubahStatus(_p.id, status);
      _berubah = true;
      await _segarkanProfil();
      if (mounted) tampilPesan(context, 'Status diubah menjadi "$status".');
    } catch (e) {
      if (mounted) tampilPesan(context, pesanError(e), error: true);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _resetSandi() async {
    final sandi = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DialogResetSandi(username: _p.username),
    );
    if (sandi == null || sandi.isEmpty) return;

    setState(() => _sibuk = true);
    try {
      await AdminRepository.resetSandi(_p.id, sandi);
      if (mounted) tampilPesan(context, 'Kata sandi berhasil direset.');
    } catch (e) {
      if (mounted) tampilPesan(context, pesanError(e), error: true);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _sibuk ? null : () => Navigator.pop(context, _berubah),
        ),
        title: const Text('Detail peserta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: 'Ubah data',
              onPressed: _sibuk ? null : _ubah,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            RCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Avatar(_p.nama, size: 64),
                  const SizedBox(height: 12),
                  Text(_p.nama,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('@${_p.username}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 10),
                  StatusAkunChip(_p.status),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  _Info(Icons.work_outline_rounded, 'Divisi', _p.divisi),
                  _Info(Icons.layers_outlined, 'Batch', _p.batch),
                  _Info(Icons.school_outlined, 'Kampus', _p.kampus),
                  _Info(Icons.phone_outlined, 'Telepon', _p.telepon),
                ],
              ),
            ),
            const SectionTitle('Status akun'),
            Segmented(
              items: const ['Aktif', 'Nonaktif', 'Selesai'],
              index: const ['aktif', 'nonaktif', 'selesai']
                  .indexOf(_p.status)
                  .clamp(0, 2),
              onChanged: _sibuk
                  ? (_) {}
                  : (i) => _gantiStatus(['aktif', 'nonaktif', 'selesai'][i]),
            ),
            const SizedBox(height: 8),
            const Text(
              'Peserta dengan status selain "Aktif" tidak dapat masuk ke aplikasi.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _sibuk ? null : _resetSandi,
                icon: const Icon(Icons.key_rounded, size: 18),
                label: const Text('Reset kata sandi',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SectionTitle('Akumulasi Kehadiran'),
            FutureBuilder<StatistikKehadiran>(
              future: AdminRepository.ambilStatistikKehadiran(_p.id),
              builder: (context, snap) {
                final s = snap.data ?? StatistikKehadiran.kosong;
                return RCard(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    children: [
                      _StatPeserta(
                        label: 'Hadir',
                        nilai: '${s.totalHadir}',
                        satuan: 'hari',
                        warna: AppColors.green,
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      Container(width: 1, height: 40, color: AppColors.line),
                      _StatPeserta(
                        label: 'Izin/Sakit',
                        nilai: '${s.totalIzinSakit}',
                        satuan: 'hari',
                        warna: const Color(0xFF2B6CB0),
                        icon: Icons.event_note_outlined,
                      ),
                      Container(width: 1, height: 40, color: AppColors.line),
                      _StatPeserta(
                        label: 'Terlambat',
                        nilai: '${s.totalTerlambat}',
                        satuan: s.totalMenitTerlambat > 0 ? '${s.totalMenitTerlambat}m' : 'kali',
                        warna: AppColors.coral,
                        icon: Icons.access_time_rounded,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SectionTitle('Riwayat presensi'),
            FutureBuilder<List<LogPresensi>>(
              future: _riwayat,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.green)),
                  );
                }
                if (snap.hasError) {
                  return InfoKosong(
                    icon: Icons.cloud_off_rounded,
                    judul: 'Gagal memuat riwayat',
                    pesan: pesanError(snap.error!),
                  );
                }
                final logs = snap.data!;
                if (logs.isEmpty) {
                  return const RCard(
                    child: InfoKosong(
                      icon: Icons.event_busy_rounded,
                      judul: 'Belum ada presensi',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final l in logs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: KartuLog(log: l, judul: tanggalId(l.waktu)),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.label, this.nilai);

  final IconData icon;
  final String label;
  final String? nilai;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.muted),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            const Spacer(),
            Flexible(
              child: Text(
                (nilai == null || nilai!.isEmpty) ? '-' : nilai!,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
            ),
          ],
        ),
      );
}

class _DialogResetSandi extends StatefulWidget {
  final String username;
  const _DialogResetSandi({required this.username});

  @override
  State<_DialogResetSandi> createState() => _DialogResetSandiState();
}

class _DialogResetSandiState extends State<_DialogResetSandi> {
  late final TextEditingController _c;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Reset kata sandi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kata sandi baru untuk @${widget.username}:',
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _c,
            autofocus: true,
            obscureText: _obscure,
            decoration: adminInput('Minimal 8 karakter', icon: Icons.key_rounded).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: AppColors.muted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.green),
          onPressed: () {
            final text = _c.text.trim();
            if (text.length < 8) {
              setState(() => _error = 'Kata sandi minimal 8 karakter');
              return;
            }
            Navigator.of(context).pop(text);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _StatPeserta extends StatelessWidget {
  const _StatPeserta({
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


