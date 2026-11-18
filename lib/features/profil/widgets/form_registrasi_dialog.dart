import 'package:flutter/material.dart';

class _DivisiOption {
  final String kode;
  final String nama;
  final String deskripsi;
  final bool aktif;

  const _DivisiOption(this.kode, this.nama, this.deskripsi,
      {required this.aktif});
}

class FormRegistrasiMagangDialog extends StatefulWidget {
  /// Dipanggil saat tombol simpan ditekan dan form valid.
  /// Lempar exception dari sini kalau gagal, pesannya tampil di dalam dialog.
  final Future<void> Function(Map<String, String> data) onSubmit;

  const FormRegistrasiMagangDialog({super.key, required this.onSubmit});

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(Map<String, String> data) onSubmit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FormRegistrasiMagangDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<FormRegistrasiMagangDialog> createState() =>
      _FormRegistrasiMagangDialogState();
}

class _FormRegistrasiMagangDialogState
    extends State<FormRegistrasiMagangDialog> {
  static const _primary = Color(0xFF4F46E5);

  static const _divisi = [
    _DivisiOption('DG', 'Desain Grafis (DG)',
        'Poster, Feed, Banner, Media Promosi',
        aktif: true),
    _DivisiOption('CC', 'Content Creator (CC)', 'Tiktok, Reels, Edukasi',
        aktif: true),
    _DivisiOption('MK', 'Marketing & Kemitraan',
        'Pemerintah, Corporate, NGO, CSR',
        aktif: true),
    _DivisiOption('WD', 'Web Development',
        'Landing Page, Feature Development, API',
        aktif: true),
  ];

  // Daftar pilihan batch magang
  static const _batches = [
    'Batch 1 (2026 Q1)',
    'Batch 2 (2026 Q2)',
    'Batch 3 (2026 Q3)',
  ];

  final _formKey = GlobalKey<FormState>();
  final _namaC = TextEditingController();
  final _teleponC = TextEditingController();
  final _emailC = TextEditingController();
  final _asalC = TextEditingController();
  final _passwordC = TextEditingController();

  int _divisiIndex = 0;
  String _batch = _batches.first;
  bool _isLoading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _namaC.dispose();
    _teleponC.dispose();
    _emailC.dispose();
    _asalC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint, {IconData? icon, Widget? suffix}) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon:
          icon == null ? null : Icon(icon, size: 20, color: Colors.black38),
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(const Color(0xFFE2E8F0)),
      focusedBorder: border(_primary, 1.5),
      errorBorder: border(Colors.red.shade300),
      focusedErrorBorder: border(Colors.red.shade400, 1.5),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B)),
        ),
      );

  String? _wajib(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onSubmit({
        'nama': _namaC.text.trim(),
        'telepon': _teleponC.text.trim(),
        'email': _emailC.text.trim(),
        'divisi': _divisi[_divisiIndex].kode,
        'batch': _batch,
        'asal': _asalC.text.trim(),
        'password': _passwordC.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(key: _formKey, child: _buildFields()),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFEEF2FF),
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'APK 1. PENDAFTARAN PESERTA',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4338CA),
                        letterSpacing: 0.3),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Form Registrasi Magang',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Data otomatis disimpan langsung ke BigData Admin',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Nama Lengkap'),
        TextFormField(
          controller: _namaC,
          textCapitalization: TextCapitalization.words,
          decoration: _dec('Contoh: Muhammad Ilham'),
          validator: _wajib,
        ),
        const SizedBox(height: 16),

        _label('No. WhatsApp / HP'),
        TextFormField(
          controller: _teleponC,
          keyboardType: TextInputType.phone,
          decoration: _dec('0812...', icon: Icons.phone_outlined),
          validator: _wajib,
        ),
        const SizedBox(height: 16),

        _label('Email Aktif'),
        TextFormField(
          controller: _emailC,
          keyboardType: TextInputType.emailAddress,
          decoration: _dec('nama@email.com', icon: Icons.mail_outline),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
            if (!v.contains('@') || !v.contains('.')) return 'Email tidak valid';
            return null;
          },
        ),
        const SizedBox(height: 16),

        const Text('Pilih Divisi / Job Spesialisasi',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 2),
        const Text('*Divisi diatur aktif/nonaktif oleh Admin',
            style: TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        _divisiGrid(),
        const SizedBox(height: 16),

        _label('Periode / Batch'),
        DropdownButtonFormField<String>(
          initialValue: _batch,
          isExpanded: true,
          decoration: _dec(''),
          items: _batches
              .map((b) => DropdownMenuItem(
                  value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) => setState(() => _batch = v ?? _batch),
        ),
        const SizedBox(height: 16),

        _label('Asal Sekolah / Kampus'),
        TextFormField(
          controller: _asalC,
          textCapitalization: TextCapitalization.words,
          decoration: _dec('Contoh: Universitas Indonesia'),
          validator: _wajib,
        ),
        const SizedBox(height: 16),

        // Khusus aplikasi: akun login butuh kata sandi awal.
        // Hapus blok ini jika backend membuat sandi otomatis.
        _label('Kata Sandi Sementara'),
        TextFormField(
          controller: _passwordC,
          obscureText: _hidePassword,
          decoration: _dec(
            'Minimal 6 karakter',
            icon: Icons.lock_outline,
            suffix: IconButton(
              icon: Icon(
                  _hidePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20),
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
            ),
          ),
          validator: (v) =>
              (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFEF3C7)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: Color(0xFFB45309)),
              SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                          text: 'Durasi: Aktif 3 Bulan. ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              'Peserta diwajibkan melakukan check-in/out harian serta mengumpulkan tugas divisi secara berkala.'),
                    ],
                  ),
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12.5)),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  /// Grid 2 kolom dengan tinggi baris otomatis mengikuti isi teks,
  /// sehingga tidak ada "BOTTOM OVERFLOWED".
  Widget _divisiGrid() {
    final rows = <Widget>[];
    for (var i = 0; i < _divisi.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _divisiCard(i)),
              const SizedBox(width: 8),
              Expanded(
                child: i + 1 < _divisi.length
                    ? _divisiCard(i + 1)
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < _divisi.length) rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }

  Widget _divisiCard(int i) {
    final d = _divisi[i];
    final selected = _divisiIndex == i;
    final enabled = d.aktif && !_isLoading;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled ? () => setState(() => _divisiIndex = i) : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _primary : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: d.aktif
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  d.aktif ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color:
                          d.aktif ? const Color(0xFF047857) : Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(d.nama,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(d.deskripsi,
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _simpan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add_alt_1, size: 18),
              label: const Text('Simpan ke BigData',
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}