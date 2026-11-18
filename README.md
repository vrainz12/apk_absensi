# Ruang Magang - Sistem Presensi & Monitoring Kinerja Magang

Aplikasi mobile berbasis Flutter dan Supabase yang dirancang untuk mengelola presensi berbasis multi-faktor (Geofencing lokasi, biometrik sidik jari, dan verifikasi wajah), serta memonitor aktivitas harian (logbook), pengajuan perizinan, dan penilaian tugas peserta magang secara terpusat dan real-time.

---

## 📌 Fitur Utama

### 1. Panel Peserta (User)
- **Multi-Factor Verification Presensi**:
  - Validasi radius geofencing kantor (lat/long) dan dukungan mode Work From Home (WFH).
  - Verifikasi biometrik perangkat (Fingerprint sensor).
  - Verifikasi wajah (*face verification*) menggunakan kamera depan.
  - Form pencatatan alasan wajib saat terlambat masuk atau pulang mendahului jadwal kerja.
- **Logbook Aktivitas Harian**:
  - Pengisian dan pemantauan kegiatan magang harian per minggu.
  - Tinjauan status logbook (*Menunggu*, *Disetujui*, *Revisi*) beserta umpan balik dari pembimbing.
- **Pengajuan Izin & Sakit**:
  - Formulir izin dengan lampiran foto/dokumen pendukung.
  - Pelacakan status persetujuan izin secara real-time.
- **Pengumpulan Tugas Divisi**:
  - Pengumpulan hasil tugas dengan pemilihan sub-tugas otomatis sesuai divisi (Web Dev, Graphic Design, Content Creator, Marketing).
  - Unggah tangkapan layar/bukti pekerjaan dan tautan repository/portofolio.
- **Sistem Notifikasi Pengingat**:
  - Notifikasi push otomatis jika belum melakukan presensi datang maupun pulang.
  - Indikator notifikasi pembaruan evaluasi admin pada ikon lonceng.

### 2. Panel Pembimbing / Administrator
- **Dashboard & Monitoring Kehadiran**:
  - Rekapitulasi kehadiran harian (Jumlah Masuk, Pulang, Belum Hadir, Izin, Terlambat).
  - Tinjauan alasan keterlambatan dan kepulangan lebih awal tiap peserta.
- **Evaluasi & Penilaian**:
  - Verifikasi dan persetujuan pengajuan izin/sakit peserta.
  - Penilaian tugas divisi lengkap dengan skor angka dan catatan pembimbing.
  - Validasi dan koreksi catatan logbook harian.
- **Manajemen Akun Peserta**:
  - Pendaftaran akun peserta baru berdasarkan divisi dan batch magang.
  - Manajemen kata sandi dan status keaktifan akun peserta.
  - Fitur ubah kata sandi akun admin.

---

## 🎨 Desain UI/UX (Figma)

Desain antarmuka pengguna (UI) dan alur pengalaman pengguna (UX) aplikasi ini dirancang secara komprehensif pada platform Figma. Seluruh tata letak halaman peserta, panel administrator, sistem warna, tipografi, serta interaksi komponen prototipe dapat diakses melalui tautan berikut:

- 🔗 **Link Mockup & Prototype Figma**:  
  [Figma Project - Mockup Aplikasi Absensi](https://www.figma.com/design/cc5OBXLilWBXqgItQOLtnO/Mockup-aplikasi-absen?node-id=0-1&t=gotFiVwLlrrsNmSY-1)

---

## 🛠️ Arsitektur & Teknologi

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK >= 3.5.0)
- **State Management**: [Flutter Riverpod](https://pub.dev/packages/flutter_riverpod)
- **Backend & Database**: [Supabase](https://supabase.com) (PostgreSQL, Row Level Security, Storage, Edge Functions)
- **Device Sensors & Vision**:
  - `geolocator`: Deteksi koordinat GPS dan kalkulasi jarak geofence.
  - `local_auth`: Autentikasi biometrik sidik jari perangkat native.
  - `google_mlkit_face_detection` & `camera`: Deteksi dan pemrosesan citra wajah.
- **Notifikasi**: `flutter_local_notifications`

---

## 🚀 Panduan Menjalankan Aplikasi

### 1. Prasyarat
- Flutter SDK (versi 3.24.x ke atas direkomendasikan)
- Android SDK (API level 34+) & Android Studio
- Akun dan project aktif di Supabase

### 2. Konfigurasi Kredensial & Database Supabase
1. **Konfigurasi API**:
   Buka file `lib/core/config/app_config.dart`, lalu sesuaikan `supabaseUrl` dan `supabaseAnonKey` dengan kredensial project Supabase Anda:
   ```dart
   static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
2. **Migrasi Database**:
   Jalankan berkas SQL yang tersedia di folder `supabase/` pada Supabase SQL Editor:
   - `admin_policies.sql` (Inisialisasi fungsi dan policy admin)
   - `security_hardening.sql` (Pengaturan Row Level Security)

### 3. Menjalankan di Lingkungan Pengembangan
```bash
# 1. Unduh seluruh dependensi paket
flutter pub get

# 2. Periksa kelaikan kode
flutter analyze

# 3. Jalankan aplikasi pada perangkat Android / emulator
flutter run
```

---

## 📁 Struktur Direktori

```text
lib/
├── core/                  # Konstanta, konfigurasi tema, service notifikasi, widget global
│   ├── constants/         # Aturan jam kerja, konstanta magang, API endpoint
│   ├── services/          # Local notifications & device utilities
│   ├── theme/             # Palet warna & tipografi aplikasi
│   └── widgets/           # Komponen UI bersama
├── features/
│   ├── admin/             # Panel admin (monitoring, evaluasi, manajemen peserta)
│   ├── auth/              # Layanan autentikasi & session Supabase
│   ├── dashboard/         # Layanan biometrik wajah & dashboard visual
│   ├── presensi/          # Formulir presensi, pengajuan izin, dan pengumpulan tugas
│   ├── profil/            # Profil pengguna, registrasi akun, dan pengaturan sandi
│   └── shell/             # Navigasi shell utama (peserta & admin)
└── main.dart              # Entry point aplikasi
```

---

## 👨‍💻 Pengembang
- **Nama**: Muhamad Zharfan
- **Topik**: Sistem Monitoring dan Presensi Magang Terpadu Berbasis Mobile
