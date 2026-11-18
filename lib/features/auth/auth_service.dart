import 'package:supabase_flutter/supabase_flutter.dart';

/// Harus sama dengan domain yang berhasil dipakai saat membuat akun
/// (di dashboard Supabase dan di Edge Function nanti).
const String kDomainInternal = 'simagang.internal';

class AuthGagal implements Exception {
  const AuthGagal(this.pesan);
  final String pesan;

  @override
  String toString() => pesan;
}

class ProfilAkun {
  const ProfilAkun({
    required this.id,
    required this.username,
    required this.nama,
    required this.role,
    required this.status,
    this.telepon,
    this.divisi,
    this.batch,
    this.kampus,
  });

  final String id;
  final String username;
  final String nama;
  final String role; // 'peserta' atau 'admin'
  final String status; // 'aktif', 'nonaktif', 'selesai'
  final String? telepon;
  final String? divisi;
  final String? batch;
  final String? kampus;

  bool get isAdmin => role == 'admin';

  factory ProfilAkun.fromMap(Map<String, dynamic> m) => ProfilAkun(
        id: m['id'].toString(),
        username: m['username']?.toString() ?? '',
        nama: m['nama']?.toString() ?? '',
        role: m['role']?.toString() ?? 'peserta',
        status: m['status']?.toString() ?? 'nonaktif',
        telepon: m['telepon']?.toString(),
        divisi: m['divisi']?.toString(),
        batch: m['batch']?.toString(),
        kampus: m['kampus']?.toString(),
      );
}

class AuthService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Username diubah menjadi email internal. Peserta tidak pernah melihat email ini.
  static String emailDariUsername(String username) =>
      '${username.trim().toLowerCase()}@$kDomainInternal';

  /// Masuk dengan username + kata sandi. Menolak akun yang tidak aktif.
  static Future<ProfilAkun> masuk(String username, String password) async {
    final u = username.trim().toLowerCase();

    // Pesan sengaja sama untuk username salah maupun kata sandi salah.
    const salah = AuthGagal('Username atau kata sandi salah.');
    if (!RegExp(r'^[a-z0-9._]{3,30}$').hasMatch(u)) throw salah;

    try {
      final res = await _db.auth.signInWithPassword(
        email: emailDariUsername(u),
        password: password,
      );
      final uid = res.user?.id;
      if (uid == null) throw const AuthGagal('Gagal masuk. Coba lagi.');

      final row =
          await _db.from('profiles').select().eq('id', uid).maybeSingle();
      if (row == null) {
        await _db.auth.signOut();
        throw const AuthGagal('Akun belum memiliki profil. Hubungi admin.');
      }

      final profil = ProfilAkun.fromMap(row);
      if (profil.status != 'aktif') {
        await _db.auth.signOut();
        throw const AuthGagal('Akun Anda tidak aktif. Hubungi admin.');
      }
      return profil;
    } on AuthGagal {
      rethrow;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login')) throw salah;
      if (msg.contains('not confirmed')) {
        throw const AuthGagal('Akun belum diaktifkan. Hubungi admin.');
      }
      throw AuthGagal('Gagal masuk: ${e.message}');
    } on PostgrestException catch (e) {
      await _db.auth.signOut();
      throw AuthGagal('Gagal membaca profil: ${e.message}');
    } catch (_) {
      throw const AuthGagal(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  /// Profil akun yang sedang login, atau null jika belum login / tidak aktif.
  static Future<ProfilAkun?> profilSaatIni() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;

    final row =
        await _db.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) return null;

    final profil = ProfilAkun.fromMap(row);
    if (profil.status != 'aktif') {
      await _db.auth.signOut();
      return null;
    }
    return profil;
  }

  static Future<void> keluar() => _db.auth.signOut();

  /// ID (uuid) akun yang sedang login. Dipakai sebagai `user_id` di
  /// presensi_logs dan data lain milik peserta.
  ///
  /// Hanya aman dipanggil di layar setelah login (di bawah AuthGate).
  static String get userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const AuthGagal('Sesi berakhir. Silakan masuk lagi.');
    return id;
  }
}