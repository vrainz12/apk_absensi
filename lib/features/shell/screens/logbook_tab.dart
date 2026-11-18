import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

const _namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

class LogbookTab extends StatefulWidget {
  const LogbookTab({super.key});

  @override
  State<LogbookTab> createState() => _LogbookTabState();
}

class _LogbookTabState extends State<LogbookTab> {
  final _catatanC = TextEditingController();
  final _kendalaC = TextEditingController();
  late final List<DateTime> _minggu;
  late int _selected;

  bool _memuatHari = true;
  bool _menyimpan = false;
  Map<String, dynamic>? _logbookHariTerpilih;

  List<Map<String, dynamic>> _riwayatLogbook = [];
  bool _memuatRiwayat = true;

  String _fmtIsoDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final senin = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    _minggu = List.generate(7, (i) => senin.add(Duration(days: i)));
    _selected = now.weekday - 1;

    _muatDataHariIniDanRiwayat();
  }

  @override
  void dispose() {
    _catatanC.dispose();
    _kendalaC.dispose();
    super.dispose();
  }

  Future<void> _muatDataHariIniDanRiwayat() async {
    await Future.wait([
      _muatLogbookTanggal(_minggu[_selected]),
      _muatRiwayat(),
    ]);
  }

  Future<void> _muatLogbookTanggal(DateTime tgl) async {
    if (!mounted) return;
    setState(() => _memuatHari = true);

    try {
      final tglStr = _fmtIsoDate(tgl);
      final res = await Supabase.instance.client
          .from('logbook_harian')
          .select()
          .eq('user_id', AuthService.userId)
          .eq('tanggal', tglStr)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _logbookHariTerpilih = res;
        _catatanC.text = res?['kegiatan']?.toString() ?? '';
        _kendalaC.text = res?['kendala']?.toString() ?? '';
      });
    } catch (e) {
      debugPrint('Error memuat logbook tanggal: $e');
      if (mounted) {
        setState(() {
          _logbookHariTerpilih = null;
          _catatanC.clear();
          _kendalaC.clear();
        });
      }
    } finally {
      if (mounted) setState(() => _memuatHari = false);
    }
  }

  Future<void> _muatRiwayat() async {
    setState(() => _memuatRiwayat = true);
    try {
      final rows = await Supabase.instance.client
          .from('logbook_harian')
          .select()
          .eq('user_id', AuthService.userId)
          .order('tanggal', ascending: false)
          .limit(14);

      if (!mounted) return;
      setState(() {
        _riwayatLogbook = List<Map<String, dynamic>>.from(rows);
      });
    } catch (e) {
      debugPrint('Error memuat riwayat logbook: $e');
    } finally {
      if (mounted) setState(() => _memuatRiwayat = false);
    }
  }

  Future<void> _simpan() async {
    final kegiatan = _catatanC.text.trim();
    if (kegiatan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tulis kegiatan harianmu terlebih dahulu.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _menyimpan = true);

    try {
      final hari = _minggu[_selected];
      final tglStr = _fmtIsoDate(hari);

      await Supabase.instance.client.from('logbook_harian').upsert({
        'user_id': AuthService.userId,
        'tanggal': tglStr,
        'kegiatan': kegiatan,
        'kendala': _kendalaC.text.trim().isEmpty ? null : _kendalaC.text.trim(),
        'status': 'menunggu',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,tanggal');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logbook ${tanggalId(hari)} berhasil disimpan! ✨'),
          backgroundColor: AppColors.green,
        ),
      );

      await _muatDataHariIniDanRiwayat();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan logbook: $e'),
          backgroundColor: AppColors.coral,
        ),
      );
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  void _pilihHari(int index) {
    if (_selected == index) return;
    setState(() => _selected = index);
    _muatLogbookTanggal(_minggu[index]);
  }

  @override
  Widget build(BuildContext context) {
    final hari = _minggu[_selected];
    final sudahDiisi = _logbookHariTerpilih != null;
    final status = _logbookHariTerpilih?['status']?.toString() ?? '';
    final isDisetujui = status.toLowerCase() == 'disetujui';
    final catatanAdmin = _logbookHariTerpilih?['catatan_admin']?.toString();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _muatDataHariIniDanRiwayat,
        color: AppColors.green,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const PageHeader(
              label: 'Logbook Harian',
              title: 'Catat langkahmu.',
            ),

            // Strip Pemilihan Hari dalam Seminggu
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pilihHari(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: i == _selected ? AppColors.green : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: i == _selected ? AppColors.green : AppColors.line,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _namaHari[i],
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: i == _selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: i == _selected
                                    ? Colors.white70
                                    : AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_minggu[i].day}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: i == _selected
                                    ? Colors.white
                                    : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Form Pengisian & Tampilan Logbook Terpilih
            RCard(
              child: _memuatHari
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Catatan ${tanggalId(hari)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Apa yang kamu kerjakan dan pelajari hari ini?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (sudahDiisi)
                              StatusChip(
                                isDisetujui ? 'Disetujui' : 'Menunggu Review',
                                fg: isDisetujui ? AppColors.green : const Color(0xFFC05621),
                                bg: isDisetujui ? AppColors.greenSoft : const Color(0xFFFEEBC8),
                              )
                            else
                              const StatusChip(
                                'Belum diisi',
                                fg: AppColors.muted,
                                bg: AppColors.bg,
                              ),
                          ],
                        ),

                        // Banner Masukan Admin jika sudah disetujui / dinilai
                        if (catatanAdmin != null && catatanAdmin.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.greenSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.green.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.green,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Catatan dari Admin / Pembimbing:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                          color: AppColors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        catatanAdmin,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.ink,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Form Kegiatan
                        TextField(
                          controller: _catatanC,
                          maxLines: 5,
                          style: const TextStyle(fontSize: 13.5, height: 1.4),
                          decoration: InputDecoration(
                            hintText: 'Tulis uraian kegiatan magangmu hari ini...',
                            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Form Kendala Opsional
                        TextField(
                          controller: _kendalaC,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13, height: 1.3),
                          decoration: InputDecoration(
                            hintText: 'Kendala yang dihadapi (opsional)...',
                            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                            filled: true,
                            fillColor: AppColors.bg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: PillButton(
                            label: _menyimpan
                                ? 'Menyimpan...'
                                : (sudahDiisi ? 'Perbarui Logbook' : 'Simpan Logbook'),
                            icon: sudahDiisi ? Icons.edit_rounded : Icons.save_rounded,
                            onPressed: _menyimpan ? null : _simpan,
                          ),
                        ),
                      ],
                    ),
            ),

            const SectionTitle('Jejak sebelumnya'),

            if (_memuatRiwayat)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.green,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (_riwayatLogbook.isEmpty)
              const RCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.menu_book_rounded, color: AppColors.muted, size: 36),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada riwayat logbook',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                            fontSize: 13.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Catatan kegiatan yang kamu simpan akan muncul di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              for (final item in _riwayatLogbook) ...[
                _LogbookHistoryCard(
                  item: item,
                  onTap: () {
                    final tgl = DateTime.tryParse(item['tanggal']?.toString() ?? '');
                    if (tgl != null) {
                      // Jika tanggal berada dalam minggu yang sedang ditampilkan, pilih tab-nya
                      final idx = _minggu.indexWhere((m) =>
                          m.year == tgl.year && m.month == tgl.month && m.day == tgl.day);
                      if (idx != -1) {
                        _pilihHari(idx);
                      } else {
                        // Tampilkan modal detail jika di luar minggu aktif
                        _tampilkanDetailModal(item);
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }

  void _tampilkanDetailModal(Map<String, dynamic> item) {
    final tglStr = item['tanggal']?.toString() ?? '';
    final dt = DateTime.tryParse(tglStr) ?? DateTime.now();
    final status = item['status']?.toString() ?? 'menunggu';
    final isDisetujui = status.toLowerCase() == 'disetujui';
    final kegiatan = item['kegiatan']?.toString() ?? '-';
    final kendala = item['kendala']?.toString();
    final catatanAdmin = item['catatan_admin']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tanggalId(dt),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                StatusChip(
                  isDisetujui ? 'Disetujui' : 'Menunggu Review',
                  fg: isDisetujui ? AppColors.green : const Color(0xFFC05621),
                  bg: isDisetujui ? AppColors.greenSoft : const Color(0xFFFEEBC8),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Uraian Kegiatan:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              kegiatan,
              style: const TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.ink),
            ),
            if (kendala != null && kendala.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Kendala:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                kendala,
                style: const TextStyle(fontSize: 13, height: 1.35, color: AppColors.coral),
              ),
            ],
            if (catatanAdmin != null && catatanAdmin.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan Admin:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            catatanAdmin,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PillButton(
                label: 'Tutup',
                background: AppColors.card,
                foreground: AppColors.ink,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogbookHistoryCard extends StatelessWidget {
  const _LogbookHistoryCard({
    required this.item,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tglStr = item['tanggal']?.toString() ?? '';
    final dt = DateTime.tryParse(tglStr) ?? DateTime.now();
    final status = item['status']?.toString() ?? 'menunggu';
    final isDisetujui = status.toLowerCase() == 'disetujui';
    final kegiatan = item['kegiatan']?.toString() ?? '';
    final catatanAdmin = item['catatan_admin']?.toString();

    const bln = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final tanggalSingkat = '${dt.day} ${bln[dt.month]}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: RCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tanggalSingkat,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.green,
                    ),
                  ),
                  Text(
                    '${dt.year}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kegiatan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.ink,
                    ),
                  ),
                  if (catatanAdmin != null && catatanAdmin.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Admin: "$catatanAdmin"',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  StatusChip(
                    isDisetujui ? 'Disetujui' : 'Menunggu',
                    fg: isDisetujui ? AppColors.green : const Color(0xFFC05621),
                    bg: isDisetujui ? AppColors.greenSoft : const Color(0xFFFEEBC8),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
