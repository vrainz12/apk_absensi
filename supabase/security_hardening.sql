-- ==============================================================================
-- Konfigurasi Keamanan dan Row Level Security (RLS) Database Supabase
-- Pengaturan hak akses, proteksi integritas data, dan validasi role pengguna
-- ==============================================================================

-- 1. FUNGSI PEMBANTU SECURITY DEFINER (Mencegah Infinite Recursion di RLS)
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role = 'admin' and status = 'aktif' from public.profiles where id = auth.uid()),
    false
  );
$$;

create or replace function public.is_aktif()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select status = 'aktif' from public.profiles where id = auth.uid()),
    false
  );
$$;

-- ------------------------------------------------------------------------------
-- 2. HARDENING TABEL: public.profiles
-- Mencegah peserta mengubah role mereka sendiri menjadi 'admin' (Privilege Escalation)
-- ------------------------------------------------------------------------------
alter table public.profiles enable row level security;

-- Reset dan konfigurasi ulang policy profiles
drop policy if exists "profil: baca semua" on public.profiles;
drop policy if exists "profil: baca milik sendiri atau admin" on public.profiles;
drop policy if exists "profil: admin boleh ubah" on public.profiles;
drop policy if exists "profil_read_policy" on public.profiles;
drop policy if exists "Allow authenticated read profiles" on public.profiles;
drop policy if exists "profil: admin kelola semua" on public.profiles;
drop policy if exists "profil: peserta hanya ubah kontak sendiri" on public.profiles;

-- BACA: Semua pengguna aktif / admin boleh melihat profil
create policy "profil: baca semua"
  on public.profiles for select to authenticated
  using (true);

-- UPDATE: Hanya admin yang boleh mengubah role, status, divisi, dan batch
create policy "profil: admin kelola semua"
  on public.profiles for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- UPDATE PESERTA: Peserta hanya boleh ubah telepon / kampus miliknya, DILARANG ubah role/status
create policy "profil: peserta hanya ubah kontak sendiri"
  on public.profiles for update to authenticated
  using (id = auth.uid() and public.is_aktif())
  with check (
    id = auth.uid()
    and role = 'peserta'
    and status = 'aktif'
  );

-- ------------------------------------------------------------------------------
-- 3. HARDENING TABEL: public.presensi_logs
-- Mengaktifkan RLS agar riwayat presensi tidak bisa dimanipulasi / dihapus peserta
-- ------------------------------------------------------------------------------
alter table public.presensi_logs add column if not exists keterangan text;
alter table public.presensi_logs enable row level security;

drop policy if exists "presensi: admin boleh baca semua" on public.presensi_logs;
drop policy if exists "presensi: baca milik sendiri atau admin" on public.presensi_logs;
drop policy if exists "presensi: peserta boleh insert" on public.presensi_logs;
drop policy if exists "presensi: tidak boleh update" on public.presensi_logs;
drop policy if exists "presensi: tidak boleh delete" on public.presensi_logs;

-- BACA: Peserta hanya bisa baca miliknya, Admin bisa baca semua
create policy "presensi: baca milik sendiri atau admin"
  on public.presensi_logs for select to authenticated
  using (user_id::text = auth.uid()::text or public.is_admin());

-- INSERT: Peserta hanya bisa mengabsen untuk dirinya sendiri, waktu tidak boleh di masa depan
create policy "presensi: peserta boleh insert"
  on public.presensi_logs for insert to authenticated
  with check (
    user_id::text = auth.uid()::text
    and public.is_aktif()
    and (
      tipe_absen in ('Masuk', 'Pulang', 'Masuk (WFH)', 'Pulang (WFH)')
      or tipe_absen like 'Masuk%'
      or tipe_absen like 'Pulang%'
    )
  );

-- Catatan: TIDAK DIBERIKAN policy UPDATE dan DELETE kepada peserta.
-- Presensi bersifat "Append-Only" (Catatan permanen / bukti absensi forensik).

-- ------------------------------------------------------------------------------
-- 4. HARDENING TABEL: public.pengumpulan_tugas
-- Mencegah peserta memberi nilai sendiri (100) atau menandai tugas selesai
-- ------------------------------------------------------------------------------
alter table public.pengumpulan_tugas enable row level security;

drop policy if exists "tugas: baca milik sendiri atau admin" on public.pengumpulan_tugas;
drop policy if exists "tugas: peserta boleh submit" on public.pengumpulan_tugas;
drop policy if exists "tugas: admin boleh beri nilai" on public.pengumpulan_tugas;
drop policy if exists "tugas: peserta boleh revisi" on public.pengumpulan_tugas;

-- BACA: Peserta baca miliknya, admin baca semua
create policy "tugas: baca milik sendiri atau admin"
  on public.pengumpulan_tugas for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- INSERT: Peserta WAJIB memasukkan status = 'menunggu', nilai = NULL, dinilai_at = NULL
create policy "tugas: peserta boleh submit"
  on public.pengumpulan_tugas for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_aktif()
    and status = 'menunggu'
    and nilai is null
    and dinilai_at is null
    and catatan_penilai is null
  );

-- UPDATE ADMIN: Admin bebas memberi nilai dan masukan evaluasi
create policy "tugas: admin boleh beri nilai"
  on public.pengumpulan_tugas for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- UPDATE PESERTA: Peserta hanya boleh memperbarui link/keterangan tugas selama status 'menunggu' / 'revisi'
create policy "tugas: peserta boleh revisi"
  on public.pengumpulan_tugas for update to authenticated
  using (user_id = auth.uid() and status in ('menunggu', 'revisi'))
  with check (
    user_id = auth.uid()
    and status = 'menunggu'
    and nilai is null
  );

-- ------------------------------------------------------------------------------
-- 5. HARDENING TABEL: public.pengajuan_izin
-- Mencegah peserta menyetujui izin mereka sendiri
-- ------------------------------------------------------------------------------
alter table public.pengajuan_izin add column if not exists foto_url text;
alter table public.pengajuan_izin enable row level security;

drop policy if exists "izin: baca milik sendiri atau admin" on public.pengajuan_izin;
drop policy if exists "izin: peserta boleh ajukan" on public.pengajuan_izin;
drop policy if exists "izin: admin boleh update status" on public.pengajuan_izin;

create policy "izin: baca milik sendiri atau admin"
  on public.pengajuan_izin for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- INSERT: Status WAJIB 'menunggu' dan catatan_admin WAJIB NULL
create policy "izin: peserta boleh ajukan"
  on public.pengajuan_izin for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_aktif()
    and status = 'menunggu'
    and catatan_admin is null
    and tanggal_mulai <= tanggal_selesai
  );

-- UPDATE: HANYA admin yang berhak menyetujui / menolak izin
create policy "izin: admin boleh update status"
  on public.pengajuan_izin for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ------------------------------------------------------------------------------
-- 6. HARDENING TABEL: public.logbook_harian
-- Mencegah peserta mengubah status logbook menjadi 'disetujui' sendiri
-- ------------------------------------------------------------------------------
alter table public.logbook_harian enable row level security;

drop policy if exists "logbook: select policy" on public.logbook_harian;
drop policy if exists "logbook: insert policy" on public.logbook_harian;
drop policy if exists "logbook: update policy" on public.logbook_harian;
drop policy if exists "logbook: baca milik sendiri atau admin" on public.logbook_harian;
drop policy if exists "logbook: peserta boleh insert" on public.logbook_harian;
drop policy if exists "logbook: peserta boleh update" on public.logbook_harian;
drop policy if exists "logbook: admin boleh update" on public.logbook_harian;

-- BACA: Peserta baca miliknya, admin baca semua
create policy "logbook: select policy"
  on public.logbook_harian for select to authenticated
  using (user_id = auth.uid() or public.is_admin());

-- INSERT: Peserta submit dengan status default 'menunggu' dan tanpa catatan admin
create policy "logbook: insert policy"
  on public.logbook_harian for insert to authenticated
  with check (
    user_id = auth.uid()
    and public.is_aktif()
    and status = 'menunggu'
    and catatan_admin is null
  );

-- UPDATE ADMIN: Admin berhak verifikasi dan beri masukan pembimbing
create policy "logbook: admin update"
  on public.logbook_harian for update to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- UPDATE PESERTA: Peserta boleh memperbarui isi catatan, TETAPI status tetap 'menunggu'
create policy "logbook: peserta update"
  on public.logbook_harian for update to authenticated
  using (user_id = auth.uid() and public.is_aktif())
  with check (
    user_id = auth.uid()
    and status = 'menunggu'
    and catatan_admin is null
  );

