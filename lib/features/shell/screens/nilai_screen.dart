import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';

class NilaiScreen extends StatefulWidget {
  const NilaiScreen({super.key});

  @override
  State<NilaiScreen> createState() => _NilaiScreenState();
}

class _NilaiScreenState extends State<NilaiScreen> {
  bool _memuat = true;
  List<Map<String, dynamic>> _listTugas = [];
  double _rataRata = 0.0;
  String? _catatanTerbaru;

  @override
  void initState() {
    super.initState();
    _muatNilai();
  }

  Future<void> _muatNilai() async {
    try {
      final res = await Supabase.instance.client
          .from('pengumpulan_tugas')
          .select()
          .eq('user_id', AuthService.userId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(res);
      final dinilai = list.where((t) => t['nilai'] != null).toList();

      double avg = 0.0;
      if (dinilai.isNotEmpty) {
        final total = dinilai.fold<num>(0, (sum, t) => sum + ((t['nilai'] as num?) ?? 0));
        avg = total / dinilai.length;
      }

      String? catatan;
      for (final t in dinilai) {
        final c = t['catatan_penilai']?.toString();
        if (c != null && c.isNotEmpty) {
          catatan = c;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _listTugas = list;
          _rataRata = avg;
          _catatanTerbaru = catatan;
          _memuat = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dinilaiCount = _listTugas.where((t) => t['nilai'] != null).length;

    return Scaffold(
      appBar: AppBar(),
      body: _memuat
          ? const Center(child: CircularProgressIndicator(color: AppColors.green))
          : RefreshIndicator(
              color: AppColors.green,
              onRefresh: _muatNilai,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  const PageHeader(label: 'Nilai', title: 'Lihat kamu bertumbuh.'),
                  RCard(
                    color: AppColors.green,
                    borderColor: AppColors.green,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: _rataRata == 0 ? 0 : (_rataRata / 100).clamp(0.0, 1.0),
                                  strokeWidth: 8,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.coral),
                                ),
                              ),
                              Text(
                                _rataRata == 0 ? '-' : _rataRata.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Nilai rata-rata tugas',
                                  style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                              const SizedBox(height: 8),
                              StatusChip(
                                '$dinilaiCount tugas dinilai',
                                fg: Colors.white,
                                bg: AppColors.coral,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_listTugas.length} total tugas dikumpulkan',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_catatanTerbaru != null) ...[
                    const SizedBox(height: 16),
                    RCard(
                      color: AppColors.coralSoft,
                      borderColor: const Color(0xFFF3CFC5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Catatan evaluasi pembimbing',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink)),
                          const SizedBox(height: 6),
                          Text(
                            _catatanTerbaru!,
                            style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.ink),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SectionTitle('Daftar nilai tugas divisi'),
                  if (_listTugas.isEmpty)
                    const RCard(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Belum ada tugas yang dikumpulkan.',
                          style: TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    for (final t in _listTugas) ...[
                      RCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: t['nilai'] != null ? AppColors.greenSoft : const Color(0xFFFBF0D8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                t['nilai'] != null ? '${t['nilai']}' : '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: t['nilai'] != null ? AppColors.green : const Color(0xFF946200),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['judul']?.toString() ?? 'Tugas',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${t['kategori']} · ${t['status'] == 'dinilai' ? "Telah Dinilai" : (t['status'] == 'revisi' ? "Perlu Revisi" : "Menunggu Evaluasi")}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(
                              t['nilai'] != null ? 'Lulus' : 'Menunggu',
                              bg: t['nilai'] != null ? AppColors.greenSoft : const Color(0xFFFBF0D8),
                              fg: t['nilai'] != null ? AppColors.green : const Color(0xFF946200),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
    );
  }
}