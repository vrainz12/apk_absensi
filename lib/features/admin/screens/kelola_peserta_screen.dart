import 'package:flutter/material.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/admin/data/admin_repository.dart';
import 'package:apk_absensi/features/admin/screens/detail_peserta_screen.dart';
import 'package:apk_absensi/features/admin/widgets/admin_widgets.dart';
import 'package:apk_absensi/features/admin/widgets/form_peserta_sheet.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class KelolaPesertaScreen extends StatefulWidget {
  const KelolaPesertaScreen({super.key});

  @override
  State<KelolaPesertaScreen> createState() => _KelolaPesertaScreenState();
}

class _KelolaPesertaScreenState extends State<KelolaPesertaScreen> {
  static const _filter = ['Semua', 'Aktif', 'Nonaktif', 'Selesai'];

  final _cariC = TextEditingController();
  List<ProfilAkun> _semua = [];
  bool _memuat = true;
  String? _error;
  int _filterIndex = 0;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _cariC.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _error = null;
    });
    try {
      final data = await AdminRepository.daftarPeserta();
      if (!mounted) return;
      setState(() => _semua = data);
    } catch (e) {
      if (mounted) setState(() => _error = pesanError(e));
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  List<ProfilAkun> get _tersaring {
    final q = _cariC.text.trim().toLowerCase();
    final status = _filterIndex == 0 ? null : _filter[_filterIndex].toLowerCase();
    return _semua.where((p) {
      if (status != null && p.status != status) return false;
      if (q.isEmpty) return true;
      return p.nama.toLowerCase().contains(q) ||
          p.username.toLowerCase().contains(q) ||
          (p.divisi ?? '').toLowerCase().contains(q) ||
          (p.kampus ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _tambah() async {
    final ok = await showFormPeserta(context);
    if (ok == true) _muat();
  }

  Future<void> _buka(ProfilAkun p) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DetailPesertaScreen(peserta: p)),
    );
    _muat();
  }

  @override
  Widget build(BuildContext context) {
    final list = _tersaring;

    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambah,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Tambah',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          onRefresh: _muat,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              PageHeader(
                label: 'Admin',
                title: 'Peserta magang',
                subtitle: _memuat ? 'Memuat...' : '${_semua.length} akun terdaftar',
              ),
              TextField(
                controller: _cariC,
                onChanged: (_) => setState(() {}),
                decoration: adminInput(
                  'Cari nama, username, divisi...',
                  icon: Icons.search_rounded,
                  suffix: _cariC.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(_cariC.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Segmented(
                items: _filter,
                index: _filterIndex,
                onChanged: (i) => setState(() => _filterIndex = i),
              ),
              const SizedBox(height: 16),
              if (_memuat)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.green)),
                )
              else if (_error != null)
                InfoKosong(
                  icon: Icons.cloud_off_rounded,
                  judul: 'Gagal memuat peserta',
                  pesan: _error,
                  onCobaLagi: _muat,
                )
              else if (list.isEmpty)
                InfoKosong(
                  icon: Icons.person_search_rounded,
                  judul: _semua.isEmpty
                      ? 'Belum ada peserta'
                      : 'Tidak ada yang cocok',
                  pesan: _semua.isEmpty
                      ? 'Tekan "Tambah" untuk membuat akun peserta pertama.'
                      : 'Coba kata kunci atau filter lain.',
                )
              else
                for (final p in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _KartuPeserta(p, onTap: () => _buka(p)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuPeserta extends StatelessWidget {
  const _KartuPeserta(this.p, {required this.onTap});

  final ProfilAkun p;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = [p.divisi, p.kampus]
        .where((s) => s != null && s.isNotEmpty)
        .join(' · ');

    return RCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Avatar(p.nama),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('@${p.username}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.muted)),
                if (info.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusAkunChip(p.status),
        ],
      ),
    );
  }
}

