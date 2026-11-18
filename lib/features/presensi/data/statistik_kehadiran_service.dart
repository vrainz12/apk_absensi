import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:apk_absensi/core/constants/magang_constants.dart';

/// Model akumulasi data kehadiran seorang peserta
class StatistikKehadiran {
  final int totalHadir;
  final int totalIzinSakit;
  final int totalTerlambat;
  final int totalMenitTerlambat;

  const StatistikKehadiran({
    required this.totalHadir,
    required this.totalIzinSakit,
    required this.totalTerlambat,
    required this.totalMenitTerlambat,
  });

  static const kosong = StatistikKehadiran(
    totalHadir: 0,
    totalIzinSakit: 0,
    totalTerlambat: 0,
    totalMenitTerlambat: 0,
  );
}

/// Service untuk menghitung akumulasi hadir, izin/sakit, dan keterlambatan
class StatistikKehadiranService {
  static final SupabaseClient _db = Supabase.instance.client;

  /// Mengambil data statistik kehadiran untuk user tertentu
  static Future<StatistikKehadiran> ambilStatistik(String userId) async {
    try {
      final hasil = await Future.wait([
        // 1. Ambil semua log presensi user
        _db
            .from('presensi_logs')
            .select('timestamp, tipe_absen')
            .eq('user_id', userId)
            .order('timestamp', ascending: true),

        // 2. Ambil izin / sakit yang telah disetujui admin
        _db
            .from('pengajuan_izin')
            .select('tanggal_mulai, tanggal_selesai, status')
            .eq('user_id', userId)
            .eq('status', 'disetujui'),
      ]);

      final logs = hasil[0] as List;
      final izins = hasil[1] as List;

      // Hitung hari hadir unik (berdasarkan tanggal masuk)
      final Set<String> tanggalHadir = {};
      int totalTerlambat = 0;
      int totalMenitTerlambat = 0;

      for (final l in logs) {
        final tsStr = l['timestamp']?.toString();
        if (tsStr == null) continue;
        final dt = MagangConstants.parseWaktuPresensi(tsStr);
        final tipe = l['tipe_absen']?.toString().toLowerCase() ?? '';

        final isMasuk = tipe.contains('masuk');
        final tglKey = '${dt.year}-${dt.month}-${dt.day}';

        if (isMasuk) {
          tanggalHadir.add(tglKey);
          if (MagangConstants.isTerlambat(dt)) {
            totalTerlambat++;
            totalMenitTerlambat += MagangConstants.menitKeterlambatan(dt);
          }
        }
      }

      // Hitung total hari izin / sakit
      int totalHariIzin = 0;
      for (final iz in izins) {
        final tglMulaiStr = iz['tanggal_mulai']?.toString();
        final tglSelesaiStr = iz['tanggal_selesai']?.toString();
        if (tglMulaiStr != null && tglSelesaiStr != null) {
          final m = DateTime.tryParse(tglMulaiStr);
          final s = DateTime.tryParse(tglSelesaiStr);
          if (m != null && s != null) {
            final selisih = s.difference(m).inDays + 1;
            totalHariIzin += selisih > 0 ? selisih : 1;
            continue;
          }
        }
        totalHariIzin++;
      }

      return StatistikKehadiran(
        totalHadir: tanggalHadir.length,
        totalIzinSakit: totalHariIzin,
        totalTerlambat: totalTerlambat,
        totalMenitTerlambat: totalMenitTerlambat,
      );
    } catch (_) {
      return StatistikKehadiran.kosong;
    }
  }
}

