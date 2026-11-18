import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';
import 'package:apk_absensi/features/presensi/data/statistik_kehadiran_service.dart';
import 'package:apk_absensi/features/profil/user/user_provider.dart';
import 'package:apk_absensi/features/profil/widgets/form_registrasi_dialog.dart';

class ProfilTab extends ConsumerWidget {
  const ProfilTab({super.key});

  String _inisial(String nama) {
    final p = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (p.isEmpty) return '?';
    if (p.length == 1) return p.first[0].toUpperCase();
    return (p.first[0] + p.last[0]).toUpperCase();
  }

  void _editProfil(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    final namaC = TextEditingController(text: user.nama);
    final emailC = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profil',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: namaC,
                decoration: const InputDecoration(labelText: 'Nama lengkap')),
            const SizedBox(height: 12),
            TextField(
                controller: emailC,
                decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green, foregroundColor: Colors.white),
            onPressed: () {
              ref
                  .read(userProvider.notifier)
                  .updateProfil(namaC.text, emailC.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profil berhasil diperbarui.')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _buatAkun(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    FormRegistrasiMagangDialog.show(
      context,
      onSubmit: (data) async {
        messenger.showSnackBar(
          const SnackBar(content: Text('Akun peserta baru berhasil didaftarkan.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isAdmin = user.role == 'admin';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const PageHeader(label: 'Profil', title: 'Ini ruangmu.'),
          RCard(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_inisial(user.nama),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.muted)),
                      const SizedBox(height: 8),
                      StatusChip(isAdmin ? 'Admin' : 'Peserta magang'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editProfil(context, ref),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const RCard(
            color: AppColors.green,
            borderColor: AppColors.green,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Minggu ke-8',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('dari 12 minggu masa magang',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                SizedBox(height: 14),
                RProgress(8 / 12,
                    color: AppColors.coral, track: Colors.white24),
              ],
            ),
          ),
          const SectionTitle('Akumulasi kehadiran kamu'),
          FutureBuilder<StatistikKehadiran>(
            future: StatistikKehadiranService.ambilStatistik(AuthService.userId),
            builder: (context, snapshot) {
              final s = snapshot.data ?? StatistikKehadiran.kosong;
              return RCard(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Row(
                  children: [
                    _StatCol(
                      label: 'Hadir',
                      nilai: '${s.totalHadir}',
                      satuan: 'hari',
                      warna: AppColors.green,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    Container(width: 1, height: 40, color: AppColors.line),
                    _StatCol(
                      label: 'Izin/Sakit',
                      nilai: '${s.totalIzinSakit}',
                      satuan: 'hari',
                      warna: const Color(0xFF2B6CB0),
                      icon: Icons.event_note_outlined,
                    ),
                    Container(width: 1, height: 40, color: AppColors.line),
                    _StatCol(
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
          const SectionTitle('Detail penempatan'),
          RCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _InfoRow(Icons.account_balance_outlined, 'Asal kampus', user.kampus),
                const Divider(height: 1, color: AppColors.line),
                _InfoRow(Icons.work_outline_rounded, 'Divisi', user.divisi),
                const Divider(height: 1, color: AppColors.line),
                const _InfoRow(Icons.date_range_outlined, 'Periode', 'Batch 1 (2026)'),
              ],
            ),
          ),
          const SectionTitle('Pengaturan'),
          RCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _MenuRow(Icons.edit_outlined, 'Edit profil',
                    () => _editProfil(context, ref)),
                if (isAdmin) ...[
                  const Divider(height: 1, color: AppColors.line),
                  _MenuRow(Icons.person_add_alt_1_rounded, 'Buat akun baru',
                      () => _buatAkun(context)),
                ],
                const Divider(height: 1, color: AppColors.line),
                _MenuRow(
                  Icons.lock_outline_rounded,
                  'Ubah kata sandi',
                  () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur ubah sandi segera hadir.')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              // AuthGate otomatis kembali ke layar login setelah keluar.
              onPressed: AuthService.keluar,
              icon: const Icon(Icons.logout_rounded, color: AppColors.coral),
              label: const Text('Keluar akun',
                  style: TextStyle(
                      color: AppColors.coral, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.coral),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink)),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({
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
