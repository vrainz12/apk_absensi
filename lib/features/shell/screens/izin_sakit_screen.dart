import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class IzinSakitScreen extends StatefulWidget {
  const IzinSakitScreen({super.key});

  @override
  State<IzinSakitScreen> createState() => _IzinSakitScreenState();
}

class _IzinSakitScreenState extends State<IzinSakitScreen> {
  final _alasanC = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  int _jenis = 0; // 0 = izin, 1 = sakit
  DateTime? _mulai;
  DateTime? _selesai;
  File? _lampiranFoto;
  bool _isLoading = false;
  List<Map<String, dynamic>> _riwayatList = [];
  bool _memuatRiwayat = true;

  @override
  void initState() {
    super.initState();
    _muatRiwayat();
  }

  Future<void> _muatRiwayat() async {
    try {
      final res = await Supabase.instance.client
          .from('pengajuan_izin')
          .select()
          .eq('user_id', AuthService.userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _riwayatList = List<Map<String, dynamic>>.from(res);
          _memuatRiwayat = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _memuatRiwayat = false);
    }
  }

  @override
  void dispose() {
    _alasanC.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal(bool mulai) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d == null) return;
    setState(() => mulai ? _mulai = d : _selesai = d);
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Pilih tanggal' : '${d.day}/${d.month}/${d.year}';

  Future<void> _pilihSumberFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unggah Foto Bukti / Surat Dokter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.green),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _ambilFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.green),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _ambilFoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ambilFoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() {
          _lampiranFoto = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Gagal memilih foto: $e');
    }
  }

  Future<void> _kirim() async {
    if (_mulai == null || _selesai == null || _alasanC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal dan alasan wajib diisi.')),
      );
      return;
    }

    if (_mulai!.isAfter(_selesai!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal mulai tidak boleh lebih dari tanggal selesai.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fotoUrl;
      if (_lampiranFoto != null) {
        final bytes = await _lampiranFoto!.readAsBytes();
        final fileName = 'izin_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('presensi_photos')
            .uploadBinary(fileName, bytes);
        fotoUrl = Supabase.instance.client.storage
            .from('presensi_photos')
            .getPublicUrl(fileName);
      }

      final jenisText = _jenis == 0 ? 'Izin' : 'Sakit';
      await Supabase.instance.client.from('pengajuan_izin').insert({
        'user_id': AuthService.userId,
        'jenis': jenisText,
        'tanggal_mulai': _mulai!.toIso8601String().split('T')[0],
        'tanggal_selesai': _selesai!.toIso8601String().split('T')[0],
        'alasan': _alasanC.text.trim(),
        'foto_url': fotoUrl,
        'status': 'menunggu',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan berhasil dikirim! Menunggu ACC Admin.')),
      );
      _alasanC.clear();
      setState(() {
        _mulai = null;
        _selesai = null;
        _lampiranFoto = null;
      });
      _muatRiwayat();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pengajuan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _bukaPratinjauFoto(String url, String judul) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const SizedBox(
                              height: 250,
                              child: Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  judul,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const PageHeader(label: 'Izin / Sakit', title: 'Ruang untuk rehat.'),
          RCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Label('Jenis pengajuan'),
                Segmented(
                  items: const ['Izin', 'Sakit'],
                  index: _jenis,
                  onChanged: (i) => setState(() => _jenis = i),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                          label: 'Mulai',
                          value: _fmt(_mulai),
                          onTap: () => _pilihTanggal(true)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                          label: 'Selesai',
                          value: _fmt(_selesai),
                          onTap: () => _pilihTanggal(false)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _Label('Alasan'),
                TextField(
                  controller: _alasanC,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Ceritakan singkat kondisimu',
                    hintStyle: const TextStyle(color: AppColors.muted),
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
                  ),
                ),
                const SizedBox(height: 16),

                // OPSI UPLOAD BUKTI / SURAT DOKTER
                const _Label('Unggah Bukti / Surat Dokter (Opsional)'),
                if (_lampiranFoto == null)
                  InkWell(
                    onTap: _pilihSumberFoto,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line, style: BorderStyle.solid),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, color: AppColors.green, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Pilih Foto / Surat Keterangan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _lampiranFoto!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                            onPressed: () => setState(() => _lampiranFoto = null),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: TextButton.icon(
                          onPressed: _pilihSumberFoto,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Ganti', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 20),
                PillButton(
                  label: _isLoading ? 'Mengirim...' : 'Kirim pengajuan',
                  onPressed: _isLoading ? null : _kirim,
                ),
              ],
            ),
          ),
          const SectionTitle('Riwayat pengajuan'),
          if (_memuatRiwayat)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.green)))
          else if (_riwayatList.isEmpty)
            const RCard(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text('Belum ada riwayat permohonan izin/sakit.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
            )
          else
            for (final r in _riwayatList) ...[
              _Riwayat(
                jenis: r['jenis']?.toString() ?? 'Izin',
                tanggal: '${r['tanggal_mulai']} s/d ${r['tanggal_selesai']}',
                status: r['status']?.toString() ?? 'menunggu',
                alasan: r['alasan']?.toString(),
                fotoUrl: r['foto_url']?.toString(),
                catatanAdmin: r['catatan_admin']?.toString(),
                onLihatFoto: r['foto_url'] != null
                    ? () => _bukaPratinjauFoto(r['foto_url'], 'Bukti ${r['jenis']}')
                    : null,
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink)),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.ink)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Riwayat extends StatelessWidget {
  const _Riwayat({
    required this.jenis,
    required this.tanggal,
    required this.status,
    this.alasan,
    this.fotoUrl,
    this.catatanAdmin,
    this.onLihatFoto,
  });

  final String jenis;
  final String tanggal;
  final String status;
  final String? alasan;
  final String? fotoUrl;
  final String? catatanAdmin;
  final VoidCallback? onLihatFoto;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    final st = status.toLowerCase();
    if (st == 'disetujui') {
      bg = AppColors.greenSoft;
      fg = AppColors.green;
    } else if (st == 'ditolak') {
      bg = AppColors.coralSoft;
      fg = AppColors.coral;
    } else {
      bg = const Color(0xFFFBF0D8);
      fg = const Color(0xFF946200);
    }

    return RCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBubble(
                jenis == 'Sakit'
                    ? Icons.healing_rounded
                    : Icons.event_busy_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jenis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(tanggal,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              StatusChip(
                status.toUpperCase(),
                fg: fg,
                bg: bg,
              ),
            ],
          ),
          if (alasan != null && alasan!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              alasan!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
            ),
          ],
          if (catatanAdmin != null && catatanAdmin!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Balasan Admin: "$catatanAdmin"',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.green),
            ),
          ],
          if (fotoUrl != null && fotoUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onLihatFoto,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fotoUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: AppColors.bg,
                        child: const Icon(Icons.broken_image, size: 20, color: AppColors.muted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Row(
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 16, color: AppColors.green),
                      SizedBox(width: 4),
                      Text(
                        'Lihat bukti foto',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
