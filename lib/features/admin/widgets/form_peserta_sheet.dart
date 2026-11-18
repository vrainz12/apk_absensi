import 'package:flutter/material.dart';

import 'package:apk_absensi/core/constants/magang_constants.dart';
import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/admin/data/admin_repository.dart';
import 'package:apk_absensi/features/admin/widgets/admin_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

/// Bottom sheet untuk menambah peserta baru (jika [peserta] null)
/// atau mengubah data peserta yang sudah ada.
///
/// Mengembalikan `true` jika data berhasil disimpan.
Future<bool?> showFormPeserta(BuildContext context, {ProfilAkun? peserta}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => FormPesertaSheet(peserta: peserta),
  );
}

class FormPesertaSheet extends StatefulWidget {
  const FormPesertaSheet({super.key, this.peserta});

  final ProfilAkun? peserta;

  @override
  State<FormPesertaSheet> createState() => _FormPesertaSheetState();
}

class _FormPesertaSheetState extends State<FormPesertaSheet> {
  final _form = GlobalKey<FormState>();
  late final _namaC = TextEditingController(text: widget.peserta?.nama);
  late final _usernameC = TextEditingController(text: widget.peserta?.username);
  final _sandiC = TextEditingController();
  late final _teleponC = TextEditingController(text: widget.peserta?.telepon);
  late final _kampusC = TextEditingController(text: widget.peserta?.kampus);

  late String _divisiTerpilih;
  late String _batchTerpilih;

  bool _sembunyi = true;
  bool _menyimpan = false;
  String? _error;

  bool get _modeEdit => widget.peserta != null;

  @override
  void initState() {
    super.initState();
    // Inisialisasi divisi
    final curDiv = widget.peserta?.divisi;
    if (curDiv != null && MagangConstants.daftarDivisi.any((d) => d.nama == curDiv || d.kode == curDiv)) {
      _divisiTerpilih = MagangConstants.daftarDivisi.firstWhere((d) => d.nama == curDiv || d.kode == curDiv).nama;
    } else {
      _divisiTerpilih = MagangConstants.daftarDivisi.last.nama; // Default Web Development
    }

    // Inisialisasi batch
    final curBatch = widget.peserta?.batch;
    if (curBatch != null && MagangConstants.listBatch.contains(curBatch)) {
      _batchTerpilih = curBatch;
    } else {
      if (curBatch != null && curBatch.isNotEmpty) {
        MagangConstants.tambahBatch(curBatch);
      }
      _batchTerpilih = curBatch ?? MagangConstants.listBatch.first;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _namaC, _usernameC, _sandiC, _teleponC, _kampusC,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _dialogTambahBatch() async {
    final c = TextEditingController();
    final baru = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Tambah Batch Baru'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: adminInput('Contoh: Batch 4 (2026 Q4)', icon: Icons.layers_rounded),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    c.dispose();

    if (baru != null && baru.isNotEmpty) {
      setState(() {
        MagangConstants.tambahBatch(baru);
        _batchTerpilih = baru;
      });
      if (mounted) tampilPesan(context, 'Batch "$baru" berhasil ditambahkan.');
    }
  }

  void _dialogHapusBatch() {
    if (MagangConstants.listBatch.length <= 1) {
      tampilPesan(context, 'Minimal harus ada 1 batch aktif.', error: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Hapus Batch'),
        content: Text('Yakin ingin menghapus "$_batchTerpilih" dari daftar batch?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () {
              setState(() {
                final dihapus = _batchTerpilih;
                MagangConstants.hapusBatch(dihapus);
                _batchTerpilih = MagangConstants.listBatch.first;
              });
              Navigator.pop(ctx);
              tampilPesan(context, 'Batch berhasil dihapus.');
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _menyimpan = true;
      _error = null;
    });

    try {
      if (_modeEdit) {
        await AdminRepository.ubahProfil(
          widget.peserta!.id,
          nama: _namaC.text,
          telepon: _teleponC.text,
          divisi: _divisiTerpilih,
          batch: _batchTerpilih,
          kampus: _kampusC.text,
        );
      } else {
        await AdminRepository.buatAkun(
          username: _usernameC.text,
          password: _sandiC.text,
          nama: _namaC.text,
          telepon: _teleponC.text,
          divisi: _divisiTerpilih,
          batch: _batchTerpilih,
          kampus: _kampusC.text,
        );
      }
      if (!mounted) return;
      tampilPesan(context,
          _modeEdit ? 'Data peserta diperbarui.' : 'Akun peserta dibuat.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = pesanError(e));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  String? _wajib(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final bawah = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bawah),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_modeEdit ? 'Ubah data peserta' : 'Tambah peserta',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                  _modeEdit
                      ? 'Username tidak dapat diubah.'
                      : 'Berikan username & kata sandi ini kepada peserta.',
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
                const FieldLabel('Nama lengkap'),
                TextFormField(
                  controller: _namaC,
                  enabled: !_menyimpan,
                  textCapitalization: TextCapitalization.words,
                  validator: _wajib,
                  decoration: adminInput('contoh: Dinda Putri',
                      icon: Icons.badge_outlined),
                ),
                const FieldLabel('Username'),
                TextFormField(
                  controller: _usernameC,
                  enabled: !_menyimpan && !_modeEdit,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: _modeEdit
                      ? null
                      : (v) {
                          final u = (v ?? '').trim().toLowerCase();
                          if (u.isEmpty) return 'Wajib diisi';
                          if (!RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(u)) {
                            return '3–30 karakter: huruf kecil, angka, titik, garis bawah';
                          }
                          return null;
                        },
                  decoration: adminInput('contoh: dinda.putri',
                      icon: Icons.alternate_email_rounded),
                ),
                if (!_modeEdit) ...[
                  const FieldLabel('Kata sandi awal'),
                  TextFormField(
                    controller: _sandiC,
                    enabled: !_menyimpan,
                    obscureText: _sembunyi,
                    autocorrect: false,
                    enableSuggestions: false,
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Minimal 8 karakter'
                        : null,
                    decoration: adminInput(
                      'Minimal 8 karakter',
                      icon: Icons.lock_outline_rounded,
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
                ],
                const FieldLabel('No. telepon'),
                TextFormField(
                  controller: _teleponC,
                  enabled: !_menyimpan,
                  keyboardType: TextInputType.phone,
                  decoration: adminInput('opsional',
                      icon: Icons.phone_outlined),
                ),
                const FieldLabel('Pilih Divisi Magang'),
                Column(
                  children: MagangConstants.daftarDivisi.map((div) {
                    final isDipilih = _divisiTerpilih == div.nama || _divisiTerpilih == div.kode;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: _menyimpan ? null : () => setState(() => _divisiTerpilih = div.nama),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDipilih ? AppColors.greenSoft.withValues(alpha: 0.5) : AppColors.bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDipilih ? AppColors.green : AppColors.line,
                              width: isDipilih ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDipilih ? AppColors.green : Colors.transparent,
                                  border: Border.all(color: isDipilih ? AppColors.green : AppColors.muted),
                                ),
                                child: isDipilih ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      div.nama,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDipilih ? AppColors.green : AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      div.deskripsi,
                                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const FieldLabel('Periode / Batch'),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: _menyimpan ? null : _dialogTambahBatch,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Tambah Batch', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.green,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        if (MagangConstants.listBatch.length > 1)
                          IconButton(
                            onPressed: _menyimpan ? null : _dialogHapusBatch,
                            icon: const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.coral),
                            tooltip: 'Hapus Batch Ini',
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: MagangConstants.listBatch.contains(_batchTerpilih) ? _batchTerpilih : MagangConstants.listBatch.first,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
                      onChanged: _menyimpan ? null : (v) {
                        if (v != null) setState(() => _batchTerpilih = v);
                      },
                      items: MagangConstants.listBatch.map((b) {
                        return DropdownMenuItem<String>(
                          value: b,
                          child: Text(b, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const FieldLabel('Kampus / sekolah'),
                TextFormField(
                  controller: _kampusC,
                  enabled: !_menyimpan,
                  textCapitalization: TextCapitalization.words,
                  decoration: adminInput('opsional',
                      icon: Icons.school_outlined),
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
                    child: Text(_error!,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.ink)),
                  ),
                ],
                const SizedBox(height: 20),
                PillButton(
                  label: _menyimpan
                      ? 'Menyimpan...'
                      : (_modeEdit ? 'Simpan perubahan' : 'Buat akun'),
                  icon: _modeEdit ? Icons.check_rounded : Icons.person_add_alt_1_rounded,
                  onPressed: _menyimpan ? null : _simpan,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
