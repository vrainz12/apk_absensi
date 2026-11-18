import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:apk_absensi/core/constants/magang_constants.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class FormTugasScreen extends StatefulWidget {
  final String? namaDivisi;

  const FormTugasScreen({
    super.key,
    this.namaDivisi,
  });

  @override
  State<FormTugasScreen> createState() => _FormTugasScreenState();
}

class _FormTugasScreenState extends State<FormTugasScreen> {
  String _divisiAktif = 'Web Development';
  String? _subTugasTerpilih;
  final _subTugasKustomController = TextEditingController();
  final _judulController = TextEditingController();
  final _keteranganController = TextEditingController();
  final _linkController = TextEditingController();
  bool _isLoading = false;
  
  // --- VARIABEL UNTUK MENYIMPAN GAMBAR ---
  File? _lampiranGambar;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _divisiAktif = widget.namaDivisi ?? 'Web Development';
    _muatDivisiPeserta();
  }

  Future<void> _muatDivisiPeserta() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('divisi')
            .eq('id', user.id)
            .maybeSingle();
        if (row != null && row['divisi'] != null) {
          final div = row['divisi'].toString();
          if (mounted && div.isNotEmpty) {
            setState(() {
              _divisiAktif = div;
              final list = MagangConstants.getSubTugasUntukDivisi(_divisiAktif);
              if (list.isNotEmpty && _subTugasTerpilih == null) {
                _subTugasTerpilih = list.first;
              }
            });
          }
        }
      }
    } catch (_) {}

    if (_subTugasTerpilih == null) {
      final list = MagangConstants.getSubTugasUntukDivisi(_divisiAktif);
      if (list.isNotEmpty && mounted) {
        setState(() => _subTugasTerpilih = list.first);
      }
    }
  }

  @override
  void dispose() {
    _subTugasKustomController.dispose();
    _judulController.dispose();
    _keteranganController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  final Color _greenDark = const Color(0xFF1B4332);
  final Color _bgColor = const Color(0xFFF9F9F6);

  Future<void> _pilihGambar() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _lampiranGambar = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Gagal memilih gambar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // --- 1. HEADER (TUGAS & TOMBOL KEMBALI) ---
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'TUGAS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.black54),
                    ),
                  ),
                ),
                const SizedBox(width: 40), 
              ],
            ),
            const SizedBox(height: 24),

            // --- 2. JUDUL HALAMAN ---
            const Text(
              'Submit Tugas Divisi',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Setiap hasil kerja adalah progres. Ceritakan dan kumpulkan pekerjaanmu di sini.',
              style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // --- 3. KARTU DIVISI (TERKUNCI) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _greenDark, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DIVISI ANDA',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text('Terkunci', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _divisiAktif,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sesuai divisi magangmu dan tidak dapat diubah.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 4. PILIHAN SUB TUGAS (PESERTA TINGGAL MEMILIH) ---
            _buildLabel('Pilih Sub Tugas Divisi', wajib: true),
            const Text(
              'Pilih salah satu sub tugas sesuai pekerjaan yang kamu selesaikan.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: MagangConstants.getSubTugasUntukDivisi(_divisiAktif).map((sub) {
                final isSelected = _subTugasTerpilih == sub;
                return GestureDetector(
                  onTap: () => setState(() => _subTugasTerpilih = sub),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? _greenDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? _greenDark : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          sub,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_subTugasTerpilih == 'Lain-lain') ...[
              const SizedBox(height: 12),
              _buildTextField(
                controller: _subTugasKustomController,
                hint: 'Ketikkan nama sub tugas lainnya di sini...',
              ),
            ],
            const SizedBox(height: 20),

            // --- 5. INPUT FORM LAINNYA ---
            _buildLabel('Judul / Topik Tugas', wajib: true),
            _buildTextField(controller: _judulController, hint: 'Contoh: Dokumentasi komponen UI'),

            _buildLabel('Keterangan & Catatan Pengerjaan'),
            _buildTextField(controller: _keteranganController, hint: 'Jelaskan ringkasan materi, progres, atau kendala yang dialami...', maxLines: 4),

            _buildLabel('Link Hasil Kerja / Portofolio', opsional: true),
            _buildTextField(controller: _linkController, hint: 'https://', prefixIcon: Icons.link_rounded),
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 20),
              child: Text('Tautan repository, website, atau hasil kerjamu.', style: TextStyle(color: Colors.black54, fontSize: 11)),
            ),

            _buildLabel('Lampiran Gambar / Bukti Hasil Kerja', opsional: true),
            GestureDetector(
              onTap: _pilihGambar,
              child: Container(
                width: double.infinity,
                padding: _lampiranGambar != null ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5), 
                ),
                child: _lampiranGambar != null 
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(
                              _lampiranGambar!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () => setState(() => _lampiranGambar = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          )
                        ],
                      )
                    : const Column(
                        children: [
                          Icon(Icons.image_outlined, size: 32, color: Color(0xFF1B4332)),
                          SizedBox(height: 12),
                          Text('Pilih gambar', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Format: JPG, PNG', style: TextStyle(color: Colors.black45, fontSize: 11)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 6. INFO BOX (PASTIKAN DETAIL & WAKTU TERKIRIM) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2EC), 
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF1B4332), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pastikan detail dan hasil kerjamu sudah sesuai. Tugas akan ditinjau oleh pembimbing.',
                      style: TextStyle(color: _greenDark, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.access_time_rounded, color: Colors.black54, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Waktu terkirim', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          'Belum dikirim. Tanggal dan jam akan tercatat saat tugas dikumpulkan.',
                          style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 7. TOMBOL KUMPULKAN TUGAS ---
            ElevatedButton(
              onPressed: _isLoading ? null : _submitTugas,
              style: ElevatedButton.styleFrom(
                backgroundColor: _greenDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLoading ? 'Mengirim Tugas...' : 'Kumpulkan Tugas', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_outward_rounded, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTugas() async {
    if (_subTugasTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih salah satu sub tugas divisi terlebih dahulu!')),
      );
      return;
    }

    final subTugas = (_subTugasTerpilih == 'Lain-lain' && _subTugasKustomController.text.trim().isNotEmpty)
        ? _subTugasKustomController.text.trim()
        : _subTugasTerpilih!;

    final judul = _judulController.text.trim();
    if (judul.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul / Topik tugas wajib diisi!')),
      );
      return;
    }

    final link = _linkController.text.trim();
    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tautan link harus diawali dengan http:// atau https://')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      String? fotoUrl;
      if (_lampiranGambar != null) {
        final bytes = await _lampiranGambar!.readAsBytes();
        final fileName = 'tugas_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('presensi_photos')
            .uploadBinary(fileName, bytes);
        fotoUrl = Supabase.instance.client.storage
            .from('presensi_photos')
            .getPublicUrl(fileName);
      }

      await Supabase.instance.client.from('pengumpulan_tugas').insert({
        'user_id': AuthService.userId,
        'nama_divisi': _divisiAktif,
        'kategori': subTugas,
        'judul': judul,
        'keterangan': _keteranganController.text.trim().isEmpty ? null : _keteranganController.text.trim(),
        'link_hasil': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        'foto_url': fotoUrl,
        'status': 'menunggu',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil dikumpulkan dan akan dinilai oleh admin!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim tugas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGET HELPER ---
  Widget _buildLabel(String text, {bool wajib = false, bool opsional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Nunito'),
          children: [
            if (wajib) const TextSpan(text: ' *Wajib', style: TextStyle(color: Colors.red)),
            if (opsional) const TextSpan(text: ' (opsional)', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade400, size: 20) : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _greenDark, width: 1.5)),
        ),
      ),
    );
  }
}