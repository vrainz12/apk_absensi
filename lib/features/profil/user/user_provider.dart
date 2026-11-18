import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Model Data Pengguna
class UserModel {
  final String nama;
  final String email;
  final String divisi;
  final String kampus;
  final String role; // 'admin' atau 'peserta'

  UserModel({
    required this.nama,
    required this.email,
    required this.divisi,
    required this.kampus,
    required this.role,
  });

  UserModel copyWith({String? nama, String? email, String? divisi, String? kampus, String? role}) {
    return UserModel(
      nama: nama ?? this.nama,
      email: email ?? this.email,
      divisi: divisi ?? this.divisi,
      kampus: kampus ?? this.kampus,
      role: role ?? this.role,
    );
  }
}

// Notifier untuk memuat & mengubah data profil dari Supabase
class UserNotifier extends StateNotifier<UserModel> {
  UserNotifier()
      : super(UserModel(
          nama: "Peserta Magang",
          email: "",
          divisi: "-",
          kampus: "-",
          role: "peserta",
        )) {
    muatDariSupabase();
  }

  Future<void> muatDariSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final row = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        state = UserModel(
          nama: row['nama']?.toString() ?? 'Peserta',
          email: row['username'] != null ? '${row['username']}@simagang' : (user.email ?? ''),
          divisi: row['divisi']?.toString() ?? 'Umum',
          kampus: row['kampus']?.toString() ?? '-',
          role: row['role']?.toString() ?? 'peserta',
        );
      }
    } catch (_) {}
  }

  void updateProfil(String namaBaru, String emailBaru) {
    state = state.copyWith(nama: namaBaru, email: emailBaru);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserModel>((ref) {
  return UserNotifier();
});
