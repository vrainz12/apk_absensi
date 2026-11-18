import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:apk_absensi/core/constants/magang_constants.dart';
import 'package:apk_absensi/features/auth/auth_service.dart';
import 'package:apk_absensi/features/presensi/data/statistik_kehadiran_service.dart';

export 'package:apk_absensi/features/presensi/data/statistik_kehadiran_service.dart'
    show StatistikKehadiran, StatistikKehadiranService;

/// Satu baris log dari tabel `presensi_logs`.
class LogPresensi {
  const LogPresensi({
    required this.id,
    required this.userId,
    required this.waktu,
    required this.tipe,
    this.biometricStatus,
    this.fotoUrl,
    this.latitude,
    this.longitude,
    this.keterangan,
  });

  final String id;
  final String userId;
  final DateTime waktu;
  final String tipe; // 'Masuk' / 'Pulang' / 'Masuk (WFH)' / 'Pulang (WFH)'
  final String? biometricStatus;
  final String? fotoUrl;
  final double? latitude;
  final double? longitude;
  final String? keterangan; // Alasan keterlambatan atau pulang lebih awal

  bool get isMasuk => tipe.toLowerCase().contains('masuk');
  bool get isPulang => tipe.toLowerCase().contains('pulang');
  bool get isWfh => tipe.toUpperCase().contains('WFH');

  String get jam =>
      '${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}';

  bool get isTerlambat => isMasuk && MagangConstants.isTerlambat(waktu);
  bool get isPulangAwal => isPulang && MagangConstants.isPulangAwal(waktu);
  int get menitTelat => isMasuk ? MagangConstants.menitKeterlambatan(waktu) : 0;
  String get statusKetepatan {
    if (!isMasuk) {
      return MagangConstants.statusPulang(waktu);
    }
    return isTerlambat ? 'Terlambat ($menitTelat mnt)' : 'Tepat Waktu';
  }

  factory LogPresensi.fromMap(Map<String, dynamic> m) => LogPresensi(
        id: m['id']?.toString() ?? '',
        userId: m['user_id']?.toString() ?? '',
        waktu: MagangConstants.parseWaktuPresensi(m['timestamp']),
        tipe: m['tipe_absen']?.toString() ?? '-',
        biometricStatus: m['biometric_status']?.toString(),
        fotoUrl: m['foto_url']?.toString(),
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        keterangan: m['keterangan']?.toString() ?? m['alasan']?.toString(),
      );
}

/// Satu pengajuan izin / sakit.
class ItemIzin {
  const ItemIzin({
    required this.id,
    required this.userId,
    required this.jenis,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.alasan,
    this.fotoUrl,
    required this.status,
    this.catatanAdmin,
    required this.createdAt,
    this.namaPeserta,
    this.divisiPeserta,
  });

  final String id;
  final String userId;
  final String jenis; // 'Izin' atau 'Sakit'
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final String alasan;
  final String? fotoUrl;
  final String status; // 'menunggu', 'disetujui', 'ditolak'
  final String? catatanAdmin;
  final DateTime createdAt;
  final String? namaPeserta;
  final String? divisiPeserta;

  bool get isMenunggu => status == 'menunggu';
  bool get isDisetujui => status == 'disetujui';
  bool get isDitolak => status == 'ditolak';

  factory ItemIzin.fromMap(Map<String, dynamic> m, [Map<String, ProfilAkun>? mapPeserta]) {
    final uid = m['user_id']?.toString() ?? '';
    final profil = mapPeserta?[uid];
    return ItemIzin(
      id: m['id']?.toString() ?? '',
      userId: uid,
      jenis: m['jenis']?.toString() ?? 'Izin',
      tanggalMulai: DateTime.tryParse(m['tanggal_mulai']?.toString() ?? '') ?? DateTime.now(),
      tanggalSelesai: DateTime.tryParse(m['tanggal_selesai']?.toString() ?? '') ?? DateTime.now(),
      alasan: m['alasan']?.toString() ?? '',
      fotoUrl: m['foto_url']?.toString(),
      status: m['status']?.toString() ?? 'menunggu',
      catatanAdmin: m['catatan_admin']?.toString(),
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      namaPeserta: profil?.nama,
      divisiPeserta: profil?.divisi,
    );
  }
}

/// Satu data pengumpulan tugas divisi.
class ItemTugas {
  const ItemTugas({
    required this.id,
    required this.userId,
    required this.namaDivisi,
    required this.kategori,
    required this.judul,
    this.keterangan,
    this.linkHasil,
    this.fotoUrl,
    this.nilai,
    this.catatanPenilai,
    required this.status,
    required this.createdAt,
    this.dinilaiAt,
    this.namaPeserta,
  });

  final String id;
  final String userId;
  final String namaDivisi;
  final String kategori;
  final String judul;
  final String? keterangan;
  final String? linkHasil;
  final String? fotoUrl;
  final int? nilai;
  final String? catatanPenilai;
  final String status; // 'menunggu', 'dinilai', 'revisi'
  final DateTime createdAt;
  final DateTime? dinilaiAt;
  final String? namaPeserta;

  bool get isDinilai => status == 'dinilai';
  bool get isMenunggu => status == 'menunggu';

  factory ItemTugas.fromMap(Map<String, dynamic> m, [Map<String, ProfilAkun>? mapPeserta]) {
    final uid = m['user_id']?.toString() ?? '';
    final profil = mapPeserta?[uid];
    return ItemTugas(
      id: m['id']?.toString() ?? '',
      userId: uid,
      namaDivisi: m['nama_divisi']?.toString() ?? (profil?.divisi ?? '-'),
      kategori: m['kategori']?.toString() ?? 'Tugas',
      judul: m['judul']?.toString() ?? '',
      keterangan: m['keterangan']?.toString(),
      linkHasil: m['link_hasil']?.toString(),
      fotoUrl: m['foto_url']?.toString(),
      nilai: (m['nilai'] as num?)?.toInt(),
      catatanPenilai: m['catatan_penilai']?.toString(),
      status: m['status']?.toString() ?? 'menunggu',
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      dinilaiAt: m['dinilai_at'] != null ? DateTime.tryParse(m['dinilai_at'].toString())?.toLocal() : null,
      namaPeserta: profil?.nama,
    );
  }
}

class ItemLogbook {
  final String id;
  final String userId;
  final DateTime tanggal;
  final String kegiatan;
  final String? kendala;
  final String status; // 'menunggu', 'disetujui'
  final String? catatanAdmin;
  final DateTime createdAt;
  final String? namaPeserta;
  final String? divisi;

  bool get isDisetujui => status.toLowerCase() == 'disetujui';
  bool get isMenunggu => status.toLowerCase() == 'menunggu';

  const ItemLogbook({
    required this.id,
    required this.userId,
    required this.tanggal,
    required this.kegiatan,
    this.kendala,
    required this.status,
    this.catatanAdmin,
    required this.createdAt,
    this.namaPeserta,
    this.divisi,
  });

  factory ItemLogbook.fromMap(Map<String, dynamic> m, [Map<String, ProfilAkun>? mapPeserta]) {
    final uid = m['user_id']?.toString() ?? '';
    final profil = mapPeserta?[uid];
    return ItemLogbook(
      id: m['id']?.toString() ?? '',
      userId: uid,
      tanggal: DateTime.tryParse(m['tanggal']?.toString() ?? '') ?? DateTime.now(),
      kegiatan: m['kegiatan']?.toString() ?? '',
      kendala: m['kendala']?.toString(),
      status: m['status']?.toString() ?? 'menunggu',
      catatanAdmin: m['catatan_admin']?.toString(),
      createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      namaPeserta: profil?.nama,
      divisi: profil?.divisi,
    );
  }
}

/// Ringkasan angka untuk halaman Beranda admin.
class RingkasanAdmin {
  const RingkasanAdmin({
    required this.totalPeserta,
    required this.pesertaAktif,
    required this.hadirHariIni,
    required this.sudahPulang,
    required this.logTerbaru,
    this.namaPeserta = const {},
    this.izinMenunggu = 0,
    this.tugasBelumDinilai = 0,
    this.logbookMenunggu = 0,
  });

  final int totalPeserta;
  final int pesertaAktif;
  final int hadirHariIni;
  final int sudahPulang;
  final List<LogPresensi> logTerbaru;
  final int izinMenunggu;
  final int tugasBelumDinilai;
  final int logbookMenunggu;

  /// user_id -> nama, untuk menampilkan nama di daftar aktivitas.
  final Map<String, String> namaPeserta;

  String namaUntuk(String userId) => namaPeserta[userId] ?? 'ID $userId';

  int get belumHadir => (pesertaAktif - hadirHariIni).clamp(0, pesertaAktif);
}

/// Semua akses data untuk panel admin.
///
/// Catatan: query ke `profiles` dan `presensi_logs` bergantung pada RLS.
/// Pastikan policy admin di `supabase/admin_policies.sql` sudah dijalankan.
class AdminRepository {
  static SupabaseClient get _db => Supabase.instance.client;

  // ---------------------------------------------------------------- Peserta

  static Future<List<ProfilAkun>> daftarPeserta() async {
    final rows = await _db
        .from('profiles')
        .select()
        .eq('role', 'peserta')
        .order('nama', ascending: true);
    return rows.map(ProfilAkun.fromMap).toList();
  }

  static Future<ProfilAkun?> ambilPeserta(String id) async {
    final row =
        await _db.from('profiles').select().eq('id', id).maybeSingle();
    return row == null ? null : ProfilAkun.fromMap(row);
  }

  static Future<void> ubahStatus(String id, String status) async {
    await _db.from('profiles').update({'status': status}).eq('id', id);
  }

  static Future<void> ubahProfil(
    String id, {
    required String nama,
    String? telepon,
    String? divisi,
    String? batch,
    String? kampus,
  }) async {
    String? kosongJadiNull(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();

    await _db.from('profiles').update({
      'nama': nama.trim(),
      'telepon': kosongJadiNull(telepon),
      'divisi': kosongJadiNull(divisi),
      'batch': kosongJadiNull(batch),
      'kampus': kosongJadiNull(kampus),
    }).eq('id', id);
  }

  /// Membuat akun peserta baru lewat Edge Function `buat-akun`.
  ///
  /// Pembuatan user Auth membutuhkan service role key, jadi TIDAK boleh
  /// dilakukan langsung dari aplikasi. Lihat `supabase/functions/buat-akun`.
  static Future<void> buatAkun({
    required String username,
    required String password,
    required String nama,
    String? telepon,
    String? divisi,
    String? batch,
    String? kampus,
  }) async {
    try {
      final res = await _db.functions.invoke('buat-akun', body: {
        'username': username.trim().toLowerCase(),
        'password': password,
        'nama': nama.trim(),
        'telepon': telepon,
        'divisi': divisi,
        'batch': batch,
        'kampus': kampus,
      });
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw AuthGagal(data['error'].toString());
      }
    } on FunctionException catch (e) {
      final d = e.details;
      final pesan = d is Map ? d['error']?.toString() : null;
      throw AuthGagal(pesan ?? 'Gagal membuat akun (kode ${e.status}).');
    }
  }

  /// Reset kata sandi peserta lewat Edge Function yang sama.
  static Future<void> resetSandi(String userId, String passwordBaru) async {
    try {
      await _db.functions.invoke('buat-akun', body: {
        'aksi': 'reset_sandi',
        'user_id': userId,
        'password': passwordBaru,
      });
    } on FunctionException catch (e) {
      final d = e.details;
      final pesan = d is Map ? d['error']?.toString() : null;
      throw AuthGagal(pesan ?? 'Gagal mereset sandi (kode ${e.status}).');
    }
  }

  // --------------------------------------------------------------- Presensi

  static Future<List<LogPresensi>> presensiPadaTanggal(DateTime tgl) async {
    final awalHari = DateTime(tgl.year, tgl.month, tgl.day, 0, 0, 0);
    // Rentang lebar agar mencakup data UTC maupun data format lama
    final rentangAwal = awalHari.subtract(const Duration(hours: 12)).toUtc().toIso8601String();
    final rentangAkhir = awalHari.add(const Duration(hours: 36)).toUtc().toIso8601String();

    final rows = await _db
        .from('presensi_logs')
        .select()
        .gte('timestamp', rentangAwal)
        .lt('timestamp', rentangAkhir)
        .order('timestamp', ascending: false);

    final list = rows.map(LogPresensi.fromMap).toList();
    // Filter presisi: hanya log yang waktu lokalnya jatuh pada hari 'tgl'
    return list.where((l) =>
        l.waktu.year == tgl.year &&
        l.waktu.month == tgl.month &&
        l.waktu.day == tgl.day).toList();
  }

  static Future<List<LogPresensi>> presensiPeserta(String userId,
      {int batas = 60}) async {
    final rows = await _db
        .from('presensi_logs')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(batas);
    return rows.map(LogPresensi.fromMap).toList();
  }

  /// Menghitung akumulasi hadir, izin/sakit, dan keterlambatan seorang peserta
  static Future<StatistikKehadiran> ambilStatistikKehadiran(String userId) =>
      StatistikKehadiranService.ambilStatistik(userId);

  static Future<RingkasanAdmin> ringkasan() async {
    final hasil = await Future.wait([
      daftarPeserta(),
      presensiPadaTanggal(DateTime.now()),
      _db.from('pengajuan_izin').select('id').eq('status', 'menunggu').count(CountOption.exact).catchError((_) => const PostgrestResponse(data: [], count: 0)),
      _db.from('pengumpulan_tugas').select('id').eq('status', 'menunggu').count(CountOption.exact).catchError((_) => const PostgrestResponse(data: [], count: 0)),
      _db.from('logbook_harian').select('id').eq('status', 'menunggu').count(CountOption.exact).catchError((_) => const PostgrestResponse(data: [], count: 0)),
    ]);
    final peserta = hasil[0] as List<ProfilAkun>;
    final logs = hasil[1] as List<LogPresensi>;
    final izinCount = (hasil[2] as PostgrestResponse).count;
    final tugasCount = (hasil[3] as PostgrestResponse).count;
    final logbookCount = (hasil[4] as PostgrestResponse).count;

    final hadir = logs.where((l) => l.isMasuk).map((l) => l.userId).toSet();
    final pulang =
        logs.where((l) => !l.isMasuk).map((l) => l.userId).toSet();

    return RingkasanAdmin(
      totalPeserta: peserta.length,
      pesertaAktif: peserta.where((p) => p.status == 'aktif').length,
      hadirHariIni: hadir.length,
      sudahPulang: pulang.length,
      logTerbaru: logs.take(6).toList(),
      namaPeserta: {for (final p in peserta) p.id: p.nama},
      izinMenunggu: izinCount,
      tugasBelumDinilai: tugasCount,
      logbookMenunggu: logbookCount,
    );
  }

  // --------------------------------------------------------------- Izin / Sakit

  static Future<List<ItemIzin>> daftarIzin({String? filterStatus}) async {
    final peserta = await daftarPeserta();
    final mapPeserta = {for (final p in peserta) p.id: p};

    final query = _db.from('pengajuan_izin').select();
    final List<dynamic> rows = (filterStatus != null && filterStatus != 'Semua')
        ? await query.eq('status', filterStatus.toLowerCase()).order('created_at', ascending: false)
        : await query.order('created_at', ascending: false);

    return rows.map((r) => ItemIzin.fromMap(r as Map<String, dynamic>, mapPeserta)).toList();
  }

  static Future<void> ubahStatusIzin(String id, String status, {String? catatan}) async {
    await _db.from('pengajuan_izin').update({
      'status': status.toLowerCase(),
      if (catatan != null) 'catatan_admin': catatan.trim(),
    }).eq('id', id);
  }

  // --------------------------------------------------------------- Tugas & Penilaian

  static Future<List<ItemTugas>> daftarTugas({String? filterStatus}) async {
    final peserta = await daftarPeserta();
    final mapPeserta = {for (final p in peserta) p.id: p};

    final query = _db.from('pengumpulan_tugas').select();
    final List<dynamic> rows = (filterStatus != null && filterStatus != 'Semua')
        ? await query.eq('status', filterStatus.toLowerCase()).order('created_at', ascending: false)
        : await query.order('created_at', ascending: false);

    return rows.map((r) => ItemTugas.fromMap(r as Map<String, dynamic>, mapPeserta)).toList();
  }

  static Future<void> beriNilaiTugas(
    String id, {
    required int nilai,
    String? catatan,
    String status = 'dinilai',
  }) async {
    await _db.from('pengumpulan_tugas').update({
      'nilai': nilai,
      'catatan_penilai': catatan?.trim(),
      'status': status.toLowerCase(),
      'dinilai_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  // --------------------------------------------------------------- Logbook Harian

  static Future<List<ItemLogbook>> daftarLogbook({String? filterStatus}) async {
    final peserta = await daftarPeserta();
    final mapPeserta = {for (final p in peserta) p.id: p};

    final query = _db.from('logbook_harian').select();
    final List<dynamic> rows = (filterStatus != null && filterStatus != 'Semua')
        ? await query.eq('status', filterStatus.toLowerCase()).order('tanggal', ascending: false)
        : await query.order('tanggal', ascending: false);

    return rows.map((r) => ItemLogbook.fromMap(r as Map<String, dynamic>, mapPeserta)).toList();
  }

  static Future<void> setujuiLogbook(String id, {String? catatanAdmin}) async {
    await _db.from('logbook_harian').update({
      'status': 'disetujui',
      if (catatanAdmin != null && catatanAdmin.trim().isNotEmpty)
        'catatan_admin': catatanAdmin.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }
}
