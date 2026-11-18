import 'package:flutter/material.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onBerhasil});

  final ValueChanged<ProfilAkun> onBerhasil;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _sembunyi = true;
  bool _memuat = false;
  String? _error;

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    final u = _usernameC.text.trim();
    final p = _passwordC.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Username dan kata sandi wajib diisi.');
      return;
    }

    setState(() {
      _memuat = true;
      _error = null;
    });

    try {
      final profil = await AuthService.masuk(u, p);
      if (!mounted) return;
      widget.onBerhasil(profil);
    } on AuthGagal catch (e) {
      if (mounted) setState(() => _error = e.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  InputDecoration _dekor(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.green, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.spa_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text('ruang magang',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.ink)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const PageHeader(
                    label: 'Masuk',
                    title: 'Selamat datang\nkembali.',
                    subtitle: 'Gunakan akun yang dibuat oleh admin.',
                  ),
                  RCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Username',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameC,
                          enabled: !_memuat,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.next,
                          decoration:
                              _dekor('contoh: dinda.putri', Icons.person_outline_rounded),
                        ),
                        const SizedBox(height: 16),
                        const Text('Kata sandi',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordC,
                          enabled: !_memuat,
                          obscureText: _sembunyi,
                          autocorrect: false,
                          enableSuggestions: false,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _masuk(),
                          decoration: _dekor(
                            'Kata sandi',
                            Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _sembunyi
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                                color: AppColors.muted,
                              ),
                              onPressed: () =>
                                  setState(() => _sembunyi = !_sembunyi),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.coralSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 18, color: AppColors.coral),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: AppColors.ink)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        PillButton(
                          label: _memuat ? 'Memeriksa...' : 'Masuk',
                          onPressed: _memuat ? null : _masuk,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum punya akun atau lupa kata sandi? Hubungi admin magang.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.45, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}