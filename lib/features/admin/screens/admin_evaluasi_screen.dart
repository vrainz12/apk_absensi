import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/admin/data/admin_repository.dart';
import 'package:apk_absensi/features/admin/widgets/admin_widgets.dart';

class AdminEvaluasiScreen extends StatefulWidget {
  const AdminEvaluasiScreen({super.key, this.tabAwal = 0});

  /// 0 = Izin/Sakit, 1 = Tugas & Nilai
  final int tabAwal;

  @override
  State<AdminEvaluasiScreen> createState() => _AdminEvaluasiScreenState();
}

class _AdminEvaluasiScreenState extends State<AdminEvaluasiScreen> {
  late int _tipeTab = widget.tabAwal;

  // State untuk Izin
  int _filterIzinIndex = 0;
  static const _filterIzin = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];
  List<ItemIzin> _listIzin = [];
  bool _memuatIzin = true;
  String? _errorIzin;

  // State untuk Tugas
  int _filterTugasIndex = 0;
  static const _filterTugas = ['Semua', 'Menunggu', 'Dinilai', 'Revisi'];
  List<ItemTugas> _listTugas = [];
  bool _memuatTugas = true;
  String? _errorTugas;

  // State untuk Logbook Harian
  int _filterLogbookIndex = 0;
  static const _filterLogbook = ['Semua', 'Menunggu', 'Disetujui'];
  List<ItemLogbook> _listLogbook = [];
  bool _memuatLogbook = true;
  String? _errorLogbook;

  @override
  void initState() {
    super.initState();
    _muatIzin();
    _muatTugas();
    _muatLogbook();
  }

  Future<void> _muatIzin() async {
    setState(() {
      _memuatIzin = true;
      _errorIzin = null;
    });
    try {
      final f = _filterIzinIndex == 0 ? null : _filterIzin[_filterIzinIndex];
      final res = await AdminRepository.daftarIzin(filterStatus: f);
      if (!mounted) return;
      setState(() => _listIzin = res);
    } catch (e) {
      if (mounted) setState(() => _errorIzin = pesanError(e));
    } finally {
      if (mounted) setState(() => _memuatIzin = false);
    }
  }

  Future<void> _muatTugas() async {
    setState(() {
      _memuatTugas = true;
      _errorTugas = null;
    });
    try {
      final f = _filterTugasIndex == 0 ? null : _filterTugas[_filterTugasIndex];
      final res = await AdminRepository.daftarTugas(filterStatus: f);
      if (!mounted) return;
      setState(() => _listTugas = res);
    } catch (e) {
      if (mounted) setState(() => _errorTugas = pesanError(e));
    } finally {
      if (mounted) setState(() => _memuatTugas = false);
    }
  }

  Future<void> _muatLogbook() async {
    setState(() {
      _memuatLogbook = true;
      _errorLogbook = null;
    });
    try {
      final f = _filterLogbookIndex == 0 ? null : _filterLogbook[_filterLogbookIndex];
      final res = await AdminRepository.daftarLogbook(filterStatus: f);
      if (!mounted) return;
      setState(() => _listLogbook = res);
    } catch (e) {
      if (mounted) setState(() => _errorLogbook = pesanError(e));
    } finally {
      if (mounted) setState(() => _memuatLogbook = false);
    }
  }

  // --- Aksi Logbook ---
  Future<void> _prosesLogbook(ItemLogbook item) async {
    final catatanC = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Setujui Logbook?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.namaPeserta ?? "Peserta"} · ${tanggalId(item.tanggal)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            Text(
              item.kegiatan,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: catatanC,
              maxLines: 2,
              decoration: adminInput('Beri masukan / catatan (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Setujui Logbook'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await AdminRepository.setujuiLogbook(item.id, catatanAdmin: catatanC.text);
        if (mounted) {
          tampilPesan(context, 'Logbook peserta telah disetujui! ✨');
          _muatLogbook();
        }
      } catch (e) {
        if (mounted) tampilPesan(context, pesanError(e), error: true);
      }
    }
    catatanC.dispose();
  }

  // --- Aksi Izin ---
  Future<void> _prosesIzin(ItemIzin item, String statusTarget) async {
    final catatanC = TextEditingController();
    final disetujui = statusTarget == 'disetujui';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(disetujui ? 'Setujui Permohonan?' : 'Tolak Permohonan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.jenis} dari ${item.namaPeserta ?? "Peserta"}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catatanC,
              maxLines: 2,
              decoration: adminInput('Catatan untuk peserta (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: disetujui ? AppColors.green : AppColors.coral,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(disetujui ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        await AdminRepository.ubahStatusIzin(item.id, statusTarget, catatan: catatanC.text);
        if (mounted) {
          tampilPesan(context, 'Pengajuan ${item.jenis} telah di-$statusTarget.');
          _muatIzin();
        }
      } catch (e) {
        if (mounted) tampilPesan(context, pesanError(e), error: true);
      }
    }
    catatanC.dispose();
  }

  // --- Aksi Nilai Tugas ---
  Future<void> _bukaFormPenilaian(ItemTugas tugas) async {
    final nilaiC = TextEditingController(text: tugas.nilai?.toString() ?? '');
    final catatanC = TextEditingController(text: tugas.catatanPenilai ?? '');
    String statusTerpilih = tugas.status == 'revisi' ? 'revisi' : 'dinilai';

    final berhasil = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  const Text('Penilaian Tugas Divisi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text('Tugas: ${tugas.judul}',
                      style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  Text('Oleh: ${tugas.namaPeserta ?? "Peserta"} · ${tugas.namaDivisi}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 16),
                  const FieldLabel('Skor Nilai (0 - 100)'),
                  TextField(
                    controller: nilaiC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: adminInput('Contoh: 85', icon: Icons.grade_rounded),
                  ),
                  const FieldLabel('Status Evaluasi'),
                  Segmented(
                    items: const ['Dinilai', 'Perlu Revisi'],
                    index: statusTerpilih == 'dinilai' ? 0 : 1,
                    onChanged: (i) => setSheetState(() => statusTerpilih = i == 0 ? 'dinilai' : 'revisi'),
                  ),
                  const FieldLabel('Catatan / Masukan Evaluasi'),
                  TextField(
                    controller: catatanC,
                    maxLines: 3,
                    decoration: adminInput('Beri masukan membangun untuk peserta...'),
                  ),
                  const SizedBox(height: 24),
                  PillButton(
                    label: 'Simpan Penilaian',
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () {
                      final n = int.tryParse(nilaiC.text.trim());
                      if (n == null || n < 0 || n > 100) {
                        tampilPesan(ctx, 'Nilai harus berupa angka 0 - 100.', error: true);
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (berhasil == true) {
      final n = int.parse(nilaiC.text.trim());
      try {
        await AdminRepository.beriNilaiTugas(
          tugas.id,
          nilai: n,
          catatan: catatanC.text,
          status: statusTerpilih,
        );
        if (mounted) {
          tampilPesan(context, 'Penilaian berhasil disimpan!');
          _muatTugas();
        }
      } catch (e) {
        if (mounted) tampilPesan(context, pesanError(e), error: true);
      }
    }
    nilaiC.dispose();
    catatanC.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: () async {
          await Future.wait([_muatIzin(), _muatTugas(), _muatLogbook()]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const PageHeader(
              label: 'Admin',
              title: 'Evaluasi & Penilaian',
              subtitle: 'Tinjau izin/sakit, evaluasi tugas, dan verifikasi logbook harian.',
            ),
            // Switcher Tab
            Segmented(
              items: const ['Izin & Sakit', 'Tugas & Nilai', 'Logbook Harian'],
              index: _tipeTab,
              onChanged: (i) => setState(() => _tipeTab = i),
            ),
            const SizedBox(height: 16),
            if (_tipeTab == 0)
              ..._buildTabIzin()
            else if (_tipeTab == 1)
              ..._buildTabTugas()
            else
              ..._buildTabLogbook(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // VIEW: TAB IZIN & SAKIT
  // =========================================================================
  List<Widget> _buildTabIzin() {
    return [
      // Filter status izin
      Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < _filterIzin.length; i++)
            ChoiceChip(
              label: Text(_filterIzin[i]),
              selected: _filterIzinIndex == i,
              selectedColor: AppColors.greenSoft,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _filterIzinIndex == i ? AppColors.green : AppColors.muted,
              ),
              onSelected: (_) {
                setState(() => _filterIzinIndex = i);
                _muatIzin();
              },
            ),
        ],
      ),
      const SizedBox(height: 14),
      if (_memuatIzin)
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator(color: AppColors.green)),
        )
      else if (_errorIzin != null)
        InfoKosong(
          icon: Icons.cloud_off_rounded,
          judul: 'Gagal memuat izin',
          pesan: _errorIzin,
          onCobaLagi: _muatIzin,
        )
      else if (_listIzin.isEmpty)
        const InfoKosong(
          icon: Icons.event_available_rounded,
          judul: 'Belum ada pengajuan izin',
          pesan: 'Permohonan izin atau sakit dari peserta akan muncul di sini.',
        )
      else
        for (final item in _listIzin)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _KartuIzin(
              item: item,
              onSetujui: () => _prosesIzin(item, 'disetujui'),
              onTolak: () => _prosesIzin(item, 'ditolak'),
            ),
          ),
    ];
  }

  // =========================================================================
  // VIEW: TAB TUGAS & PENILAIAN
  // =========================================================================
  List<Widget> _buildTabTugas() {
    return [
      Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < _filterTugas.length; i++)
            ChoiceChip(
              label: Text(_filterTugas[i]),
              selected: _filterTugasIndex == i,
              selectedColor: AppColors.greenSoft,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _filterTugasIndex == i ? AppColors.green : AppColors.muted,
              ),
              onSelected: (_) {
                setState(() => _filterTugasIndex = i);
                _muatTugas();
              },
            ),
        ],
      ),
      const SizedBox(height: 14),
      if (_memuatTugas)
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator(color: AppColors.green)),
        )
      else if (_errorTugas != null)
        InfoKosong(
          icon: Icons.cloud_off_rounded,
          judul: 'Gagal memuat tugas',
          pesan: _errorTugas,
          onCobaLagi: _muatTugas,
        )
      else if (_listTugas.isEmpty)
        const InfoKosong(
          icon: Icons.assignment_outlined,
          judul: 'Belum ada tugas dikumpulkan',
          pesan: 'Tugas yang disubmit peserta divisi akan tampil di sini untuk dievaluasi.',
        )
      else
        for (final item in _listTugas)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _KartuTugas(
              item: item,
              onNilai: () => _bukaFormPenilaian(item),
            ),
          ),
    ];
  }

  // =========================================================================
  // VIEW: TAB LOGBOOK HARIAN
  // =========================================================================
  List<Widget> _buildTabLogbook() {
    return [
      Wrap(
        spacing: 8,
        children: [
          for (var i = 0; i < _filterLogbook.length; i++)
            ChoiceChip(
              label: Text(_filterLogbook[i]),
              selected: _filterLogbookIndex == i,
              selectedColor: AppColors.greenSoft,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _filterLogbookIndex == i ? AppColors.green : AppColors.muted,
              ),
              onSelected: (_) {
                setState(() => _filterLogbookIndex = i);
                _muatLogbook();
              },
            ),
        ],
      ),
      const SizedBox(height: 14),
      if (_memuatLogbook)
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(child: CircularProgressIndicator(color: AppColors.green)),
        )
      else if (_errorLogbook != null)
        InfoKosong(
          icon: Icons.cloud_off_rounded,
          judul: 'Gagal memuat logbook',
          pesan: _errorLogbook,
          onCobaLagi: _muatLogbook,
        )
      else if (_listLogbook.isEmpty)
        const InfoKosong(
          icon: Icons.menu_book_rounded,
          judul: 'Belum ada logbook',
          pesan: 'Catatan logbook harian dari peserta magang akan tampil di sini.',
        )
      else
        for (final item in _listLogbook)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _KartuLogbook(
              item: item,
              onSetujui: () => _prosesLogbook(item),
            ),
          ),
    ];
  }
}

// ===========================================================================
// DIALOG PRATINJAU FOTO
// ===========================================================================
void _bukaPratinjauFoto(BuildContext context, String url, String judul) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 560),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                  errorBuilder: (_, err, ___) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Gagal memuat gambar',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ===========================================================================
// WIDGET KARTU IZIN
// ===========================================================================
class _KartuIzin extends StatelessWidget {
  const _KartuIzin({
    required this.item,
    required this.onSetujui,
    required this.onTolak,
  });

  final ItemIzin item;
  final VoidCallback onSetujui;
  final VoidCallback onTolak;

  String _formatTgl(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeFg;
    if (item.isDisetujui) {
      badgeBg = AppColors.greenSoft;
      badgeFg = AppColors.green;
    } else if (item.isDitolak) {
      badgeBg = AppColors.coralSoft;
      badgeFg = AppColors.coral;
    } else {
      badgeBg = const Color(0xFFFBF0D8);
      badgeFg = const Color(0xFF946200);
    }

    return RCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(item.namaPeserta ?? 'Peserta', size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaPeserta ?? 'Peserta',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                    ),
                    Text(
                      '${item.jenis} · ${item.divisiPeserta ?? "Magang"}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusChip(
                item.status.toUpperCase(),
                bg: badgeBg,
                fg: badgeFg,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Text(
                  '${_formatTgl(item.tanggalMulai)}  s/d  ${_formatTgl(item.tanggalSelesai)}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.alasan,
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
          ),
          if (item.catatanAdmin != null && item.catatanAdmin!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan Admin: ${item.catatanAdmin}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.muted),
            ),
          ],
          if (item.fotoUrl != null && item.fotoUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _bukaPratinjauFoto(context, item.fotoUrl!, 'Bukti ${item.jenis}'),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.fotoUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(12),
                        color: AppColors.bg,
                        child: const Row(
                          children: [
                            Icon(Icons.broken_image_rounded, color: AppColors.coral),
                            SizedBox(width: 8),
                            Expanded(child: Text('Foto bukti tidak dapat dibuka', style: TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 4),
                        Text(
                          'Lihat Bukti Foto',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.isMenunggu) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTolak,
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.coral),
                    label: const Text('Tolak', style: TextStyle(color: AppColors.coral, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.coral),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onSetujui,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// WIDGET KARTU TUGAS & PENILAIAN
// ===========================================================================
class _KartuTugas extends StatelessWidget {
  const _KartuTugas({
    required this.item,
    required this.onNilai,
  });

  final ItemTugas item;
  final VoidCallback onNilai;

  @override
  Widget build(BuildContext context) {
    return RCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(item.namaPeserta ?? 'Peserta', size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaPeserta ?? 'Peserta',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                    ),
                    Text(
                      '${item.namaDivisi} · ${item.kategori}',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (item.nilai != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Nilai: ${item.nilai}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                )
              else
                StatusChip(
                  item.status == 'revisi' ? 'Revisi' : 'Menunggu',
                  bg: item.status == 'revisi' ? AppColors.coralSoft : const Color(0xFFFBF0D8),
                  fg: item.status == 'revisi' ? AppColors.coral : const Color(0xFF946200),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.judul,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink),
          ),
          if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.keterangan!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.4),
            ),
          ],
          if (item.linkHasil != null && item.linkHasil!.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: item.linkHasil!));
                tampilPesan(context, 'Tautan link disalin ke clipboard.');
              },
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, size: 16, color: AppColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.linkHasil!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.green, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.fotoUrl != null && item.fotoUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _bukaPratinjauFoto(context, item.fotoUrl!, 'Lampiran Tugas: ${item.judul}'),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.fotoUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : Container(
                              height: 160,
                              color: AppColors.bg,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.green,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        padding: const EdgeInsets.all(12),
                        color: AppColors.bg,
                        child: const Row(
                          children: [
                            Icon(Icons.broken_image_rounded, color: AppColors.coral),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Foto lampiran tidak dapat dibuka.',
                                style: TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 4),
                        Text(
                          'Ketuk untuk perbesar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.catatanPenilai != null && item.catatanPenilai!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rate_review_outlined, size: 16, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Evaluasi: ${item.catatanPenilai}',
                      style: const TextStyle(fontSize: 12, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onNilai,
              icon: Icon(item.nilai != null ? Icons.edit_note_rounded : Icons.star_border_rounded, size: 18),
              label: Text(item.nilai != null ? 'Ubah Penilaian' : 'Beri Nilai & Evaluasi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuLogbook extends StatelessWidget {
  const _KartuLogbook({
    required this.item,
    required this.onSetujui,
  });

  final ItemLogbook item;
  final VoidCallback onSetujui;

  @override
  Widget build(BuildContext context) {
    final disetujui = item.isDisetujui;

    return RCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaPeserta ?? 'Peserta Magang',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.divisi ?? "Divisi"} · ${tanggalId(item.tanggal)}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusChip(
                disetujui ? 'Disetujui' : 'Menunggu',
                fg: disetujui ? AppColors.green : const Color(0xFFC05621),
                bg: disetujui ? AppColors.greenSoft : const Color(0xFFFEEBC8),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Uraian Kegiatan:',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.muted),
          ),
          const SizedBox(height: 3),
          Text(
            item.kegiatan,
            style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
          ),
          if (item.kendala != null && item.kendala!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Kendala:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              item.kendala!,
              style: const TextStyle(fontSize: 12.5, height: 1.3, color: AppColors.coral),
            ),
          ],
          if (item.catatanAdmin != null && item.catatanAdmin!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.greenSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_rounded, size: 16, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan Admin: ${item.catatanAdmin}',
                      style: const TextStyle(fontSize: 12, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: disetujui
                ? OutlinedButton.icon(
                    onPressed: onSetujui,
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    label: const Text('Ubah Catatan / Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onSetujui,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Setujui Logbook'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

