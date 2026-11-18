import 'package:flutter/material.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';

/// Dekorasi input yang sama dengan layar login.
InputDecoration adminInput(String hint, {IconData? icon, Widget? suffix}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
    prefixIcon:
        icon == null ? null : Icon(icon, size: 20, color: AppColors.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.bg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.green, 1.5),
    errorBorder: border(AppColors.coral),
    focusedErrorBorder: border(AppColors.coral, 1.5),
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 14),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
      );
}

/// Chip warna sesuai status akun.
class StatusAkunChip extends StatelessWidget {
  const StatusAkunChip(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'aktif':
        return const StatusChip('Aktif');
      case 'selesai':
        return const StatusChip('Selesai',
            fg: Color(0xFF8A6D1F), bg: Color(0xFFF5EBCB));
      default:
        return const StatusChip('Nonaktif',
            fg: AppColors.coral, bg: AppColors.coralSoft);
    }
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.nama, {super.key, this.size = 44});
  final String nama;
  final double size;

  String get _inisial {
    final p = nama.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (p.isEmpty) return '?';
    return p.take(2).map((s) => s[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.greenSoft,
          borderRadius: BorderRadius.circular(size / 3),
        ),
        child: Text(_inisial,
            style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                color: AppColors.green)),
      );
}

/// Tampilan kosong / error yang konsisten.
class InfoKosong extends StatelessWidget {
  const InfoKosong({
    super.key,
    required this.icon,
    required this.judul,
    this.pesan,
    this.onCobaLagi,
  });

  final IconData icon;
  final String judul;
  final String? pesan;
  final VoidCallback? onCobaLagi;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          children: [
            IconBubble(icon, size: 56),
            const SizedBox(height: 14),
            Text(judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink)),
            if (pesan != null) ...[
              const SizedBox(height: 6),
              Text(pesan!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.45, color: AppColors.muted)),
            ],
            if (onCobaLagi != null) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: onCobaLagi,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      );
}

void tampilPesan(BuildContext context, String pesan, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(pesan),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.coral : AppColors.green,
    ));
}

String pesanError(Object e) {
  final s = e.toString();
  if (s.contains('SocketException') || s.contains('Failed host lookup')) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
  }
  return s.replaceFirst('Exception: ', '');
}

