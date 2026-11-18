class DivisiMagang {
  final String kode;
  final String nama;
  final String deskripsi;

  const DivisiMagang({
    required this.kode,
    required this.nama,
    required this.deskripsi,
  });
}

class MagangConstants {
  // 4 Divisi Resmi
  static const List<DivisiMagang> daftarDivisi = [
    DivisiMagang(
      kode: 'DG',
      nama: 'Desain Grafis (DG)',
      deskripsi: 'Poster, Feed, Banner, Media Promosi',
    ),
    DivisiMagang(
      kode: 'CC',
      nama: 'Content Creator (CC)',
      deskripsi: 'Tiktok, Reels, Edukasi',
    ),
    DivisiMagang(
      kode: 'MK',
      nama: 'Marketing & Kemitraan',
      deskripsi: 'Pemerintah, Corporate, NGO, CSR',
    ),
    DivisiMagang(
      kode: 'WD',
      nama: 'Web Development',
      deskripsi: 'Landing Page, Feature Development, API',
    ),
  ];

  // Aturan Jam Kerja
  static const int jamMasukBatas = 9; // Jam 09:00
  static const int menitMasukBatas = 0;

  static const int jamPulangMulai = 16; // Jam 16:00 (Jam 4 sore)
  static const int menitPulangMulai = 0;

  static const int jamPulangBatas = 17; // Jam 17:00 (Jam 5 sore)
  static const int menitPulangBatas = 0;

  /// Mengonversi nilai timestamp dari database menjadi DateTime lokal (WIB) secara presisi.
  /// Otomatis mendeteksi dan mengoreksi data yang mengalami double-offset (+7 jam di masa depan).
  static DateTime parseWaktuPresensi(dynamic val) {
    if (val == null) return DateTime.now();
    DateTime dt = DateTime.tryParse(val.toString())?.toLocal() ?? DateTime.now();

    // Jika waktu hasil parse berada di masa depan (>15 menit dari jam perangkat sekarang),
    // artinya data lama tersimpan sebagai waktu lokal yang salah diinterpretasikan sebagai UTC oleh Postgres.
    final now = DateTime.now();
    if (dt.isAfter(now) && dt.difference(now).inMinutes > 15) {
      dt = dt.subtract(dt.timeZoneOffset);
    }
    return dt;
  }

  /// Memeriksa apakah absen masuk berstatus terlambat (lewat dari jam 09:00)
  static bool isTerlambat(DateTime waktu) {
    if (waktu.hour > jamMasukBatas) return true;
    if (waktu.hour == jamMasukBatas && waktu.minute > menitMasukBatas) return true;
    return false;
  }

  /// Menghitung berapa menit keterlambatan jika masuk lewat dari jam 09:00
  static int menitKeterlambatan(DateTime waktu) {
    if (!isTerlambat(waktu)) return 0;
    final batas = DateTime(waktu.year, waktu.month, waktu.day, jamMasukBatas, menitMasukBatas);
    return waktu.difference(batas).inMinutes;
  }

  /// Memeriksa apakah waktu saat ini berada di rentang absen pulang (16:00 - 17:00)
  static bool bolehAbsenPulang(DateTime waktu) {
    // Lewat dari jam 16:00 dan belum lewat jam 17:00
    if (waktu.hour < jamPulangMulai) return false;
    if (waktu.hour > jamPulangBatas) return false;
    if (waktu.hour == jamPulangBatas && waktu.minute > menitPulangBatas) return false;
    return true;
  }

  /// Memeriksa apakah absen pulang dilakukan lebih awal (sebelum jam 16:00)
  static bool isPulangAwal(DateTime waktu) {
    if (waktu.hour < jamPulangMulai) return true;
    if (waktu.hour == jamPulangMulai && waktu.minute < menitPulangMulai) return true;
    return false;
  }

  /// Keterangan status pulang
  static String statusPulang(DateTime waktu) {
    if (waktu.hour < jamPulangMulai) {
      return 'Pulang Awal (Sebelum 16:00)';
    } else if (waktu.hour > jamPulangBatas || (waktu.hour == jamPulangBatas && waktu.minute > menitPulangBatas)) {
      return 'Lewat Batas (Setelah 17:00)';
    }
    return 'Normal';
  }

  // --- KELOLA BATCH (Default 3 batch dalam setahun, bisa ditambah/dikurang admin) ---
  static List<String> listBatch = [
    'Batch 1 (2026 Q1)',
    'Batch 2 (2026 Q2)',
    'Batch 3 (2026 Q3)',
  ];

  static void tambahBatch(String namaBatch) {
    final b = namaBatch.trim();
    if (b.isNotEmpty && !listBatch.contains(b)) {
      listBatch.add(b);
    }
  }

  static void hapusBatch(String namaBatch) {
    if (listBatch.length > 1) {
      listBatch.remove(namaBatch);
    }
  }

  /// Daftar Sub Tugas pilihan resmi untuk setiap divisi
  static List<String> getSubTugasUntukDivisi(String namaDivisi) {
    final lower = namaDivisi.toLowerCase();
    if (lower.contains('desain') || lower.contains('dg')) {
      return const [
        'Poster',
        'Feed Instagram',
        'Banner Promosi',
        'Media Promosi',
        'Desain Merchandise',
        'Lain-lain',
      ];
    } else if (lower.contains('content') || lower.contains('creator') || lower.contains('cc')) {
      return const [
        'Tiktok Video',
        'Reels Instagram',
        'Konten Edukasi',
        'Script / Storyboard',
        'Voice Over & Editing',
        'Lain-lain',
      ];
    } else if (lower.contains('marketing') || lower.contains('kemitraan') || lower.contains('mk')) {
      return const [
        'Kerjasama Pemerintah',
        'Partnership Corporate',
        'Program NGO / Komunitas',
        'Program CSR',
        'Riset Mitra Baru',
        'Lain-lain',
      ];
    } else {
      // Default / Web Development
      return const [
        'Landing Page',
        'Feature Development',
        'API Backend',
        'Slicing UI Flutter / Web',
        'Bug Fixing & Maintenance',
        'Database & Storage',
        'Lain-lain',
      ];
    }
  }
}

