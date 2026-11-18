import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/admin/widgets/admin_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class AdminAkunScreen extends StatelessWidget {
  const AdminAkunScreen({super.key, required this.profil});

  final ProfilAkun profil;

  Future<void> _gantiSandi(BuildContext context) async {
    final berhasil = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _DialogGantiSandiAdmin(),
    );

    if (berhasil == true && context.mounted) {
      tampilPesan(context, 'Kata sandi admin berhasil diperbarui! 🔐');
    }
  }

  Future<void> _keluar(BuildContext context) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar akun?'),
        content: const Text('Anda perlu masuk kembali untuk membuka panel admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    // AuthGate akan otomatis menampilkan layar login setelah signOut.
    if (ya == true) await AuthService.keluar();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const PageHeader(label: 'Admin', title: 'Akun saya'),
          RCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Avatar(profil.nama, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profil.nama,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${profil.username}',
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      const StatusChip('Administrator'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SectionTitle('Keamanan'),
          InkWell(
            onTap: () => _gantiSandi(context),
            borderRadius: BorderRadius.circular(18),
            child: const RCard(
              child: Row(
                children: [
                  IconBubble(Icons.lock_outline_rounded, bg: AppColors.greenSoft, fg: AppColors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ganti kata sandi admin',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 13.5),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Perbarui sandi akun admin agar aman',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ],
              ),
            ),
          ),

          const SectionTitle('Tentang'),
          const RCard(
            child: Row(
              children: [
                IconBubble(Icons.spa_rounded),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ruang magang',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
                      ),
                      Text(
                        'Panel admin · versi 1.0.0',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _keluar(context),
              icon: const Icon(Icons.logout_rounded, color: AppColors.coral),
              label: const Text(
                'Keluar akun',
                style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.coral),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogGantiSandiAdmin extends StatefulWidget {
  const _DialogGantiSandiAdmin();

  @override
  State<_DialogGantiSandiAdmin> createState() => _DialogGantiSandiAdminState();
}

class _DialogGantiSandiAdminState extends State<_DialogGantiSandiAdmin> {
  late final TextEditingController _sandiBaruC;
  late final TextEditingController _konfirmasiC;
  bool _sembunyikanSandi = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sandiBaruC = TextEditingController();
    _konfirmasiC = TextEditingController();
  }

  @override
  void dispose() {
    _sandiBaruC.dispose();
    _konfirmasiC.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final sandi = _sandiBaruC.text.trim();
    final konfirm = _konfirmasiC.text.trim();

    if (sandi.length < 8) {
      setState(() => _error = 'Kata sandi minimal 8 karakter!');
      return;
    }
    if (sandi != konfirm) {
      setState(() => _error = 'Konfirmasi kata sandi tidak cocok!');
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: sandi),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Gagal mengganti kata sandi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.green, size: 24),
          SizedBox(width: 8),
          Text('Ganti Kata Sandi Admin', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pastikan kata sandi baru kuat dan tidak mudah ditebak peserta.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.coralSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.coral, fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const FieldLabel('Kata Sandi Baru'),
            TextField(
              controller: _sandiBaruC,
              obscureText: _sembunyikanSandi,
              decoration: adminInput('Minimal 8 karakter', icon: Icons.key_rounded).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _sembunyikanSandi ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _sembunyikanSandi = !_sembunyikanSandi),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const FieldLabel('Konfirmasi Kata Sandi'),
            TextField(
              controller: _konfirmasiC,
              obscureText: _sembunyikanSandi,
              decoration: adminInput('Ulangi kata sandi baru', icon: Icons.lock_outline_rounded),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.green),
          onPressed: _simpan,
          child: const Text('Simpan Sandi'),
        ),
      ],
    );
  }
}
