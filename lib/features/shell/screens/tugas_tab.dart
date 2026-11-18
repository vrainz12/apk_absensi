import 'package:flutter/material.dart';

import 'package:apk_absensi/core/theme/app_theme.dart';
import 'package:apk_absensi/core/widgets/ruang_widgets.dart';

class _Task {
  const _Task(this.title, this.due, this.done, this.progress);

  final String title;
  final String due;
  final bool done;
  final double progress;
}

// Data contoh. Ganti dengan data dari API.
const _tasks = [
  _Task('Selesaikan halaman login', 'Tenggat 6 Nov', false, 0.7),
  _Task('Integrasi API data peserta', 'Tenggat 9 Nov', false, 0.4),
  _Task('Dokumentasi komponen UI', 'Tenggat 12 Nov', false, 0.1),
  _Task('Desain poster rekrutmen batch 2', 'Dikumpulkan 19 Okt', true, 1),
];

class TugasTab extends StatefulWidget {
  const TugasTab({super.key, required this.onKumpulkan});

  /// Membuka FormTugasScreen (pilih file + kirim).
  final VoidCallback onKumpulkan;

  @override
  State<TugasTab> createState() => _TugasTabState();
}

class _TugasTabState extends State<TugasTab> {
  static const _filters = ['Semua', 'Aktif', 'Selesai'];
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final list = _tasks.where((t) {
      if (_filter == 1) return !t.done;
      if (_filter == 2) return t.done;
      return true;
    }).toList();
    final selesai = _tasks.where((t) => t.done).length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const PageHeader(label: 'Tugas', title: 'Satu per satu, tuntas.'),
          RCard(
            color: AppColors.green,
            borderColor: AppColors.green,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${selesai.toString().padLeft(2, '0')}/${_tasks.length.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1),
                    ),
                    const SizedBox(width: 10),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('tugas selesai',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RProgress(
                  selesai / _tasks.length,
                  color: AppColors.coral,
                  track: Colors.white24,
                  height: 8,
                ),
                const SizedBox(height: 18),
                PillButton(
                  label: 'Kumpulkan tugas',
                  icon: Icons.upload_file_rounded,
                  background: AppColors.bg,
                  foreground: AppColors.green,
                  onPressed: widget.onKumpulkan,
                ),
              ],
            ),
          ),
          const SectionTitle('Prioritas minggu ini'),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < _filters.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _filter = i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: i == _filter ? AppColors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: i == _filter
                              ? AppColors.green
                              : AppColors.line),
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: i == _filter ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (final t in list) ...[
            RCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: AppColors.ink)),
                            const SizedBox(height: 3),
                            Text(t.due,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        t.done ? 'Selesai' : 'Aktif',
                        fg: t.done ? AppColors.green : AppColors.coral,
                        bg: t.done ? AppColors.greenSoft : AppColors.coralSoft,
                      ),
                    ],
                  ),
                  if (!t.done) ...[
                    const SizedBox(height: 12),
                    RProgress(t.progress, height: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}