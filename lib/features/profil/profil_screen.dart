import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apk_absensi/features/profil/widgets/form_registrasi_dialog.dart';
import 'user/user_provider.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  // Dialog untuk Edit Profil (Nama & Email)
  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    final nameController = TextEditingController(text: user.nama);
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            onPressed: () {
              ref.read(userProvider.notifier).updateProfil(nameController.text, emailController.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profil berhasil diperbarui!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  // Dialog Khusus Admin untuk Membuat Akun Peserta Baru
  // (tampilan baru: Form Registrasi Magang, sama seperti versi web)
  void _showCreateAccountAdminDialog(BuildContext context) {
    // Simpan messenger sebelum dialog dibuka, supaya aman dipakai setelah await.
    final messenger = ScaffoldMessenger.of(context);

    FormRegistrasiMagangDialog.show(
      context,
      onSubmit: (data) async {
        // Pendaftaran akun peserta baru
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Akun peserta baru berhasil didaftarkan oleh Admin!"),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final isAdmin = user.role == 'admin'; // Pengecekan Hak Akses

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Center(
            child: Text(
              "Profil Saya",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 24),

          // FOTO & INFO SINGKAT (Reactive dari Riverpod)
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF6366F1), width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Icon(Icons.person, size: 50, color: Color(0xFF6366F1)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.nama,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${user.divisi} • ${isAdmin ? 'Admin' : 'Peserta'}",
                    style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // KARTU DATA MAGANG (Terkunci dari pengguna)
          const Text("Data Magang (Terkunci oleh Sistem)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildListTile(Icons.account_balance, "Asal Kampus / Instansi", trailingText: user.kampus),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildListTile(Icons.date_range, "Periode Batch", trailingText: "Batch 1 (2026)"),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildListTile(Icons.security, "Hak Akses Akun", trailingText: isAdmin ? "Administrator" : "Peserta Magang"),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PENGATURAN AKUN
          const Text("Pengaturan Akun", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // Tombol Edit Profil (Nama & Email)
                _buildListTile(Icons.edit, "Edit Profil", showArrow: true, onTap: () => _showEditProfileDialog(context, ref)),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // KONTROL KHUSUS ADMIN: Hanya muncul jika role == 'admin'
                if (isAdmin) ...[
                  _buildListTile(Icons.person_add_alt_1, "Buat Akun Baru (Admin Only)", showArrow: true, onTap: () => _showCreateAccountAdminDialog(context)),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],

                _buildListTile(Icons.lock_outline, "Ubah Kata Sandi", showArrow: true, onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur ubah sandi")));
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // TOMBOL KELUAR
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Logika keluar akun
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text(
                "Keluar Akun",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? trailingText, bool showArrow = false, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: trailingText != null
          ? Text(trailingText, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold))
          : showArrow
              ? const Icon(Icons.chevron_right, color: Colors.black54)
              : null,
    );
  }
}