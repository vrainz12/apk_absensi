-- Policy RLS untuk panel admin.
-- Jalankan sekali di Supabase Dashboard -> SQL Editor.

-- Fungsi pembantu. SECURITY DEFINER agar tidak terjadi rekursi RLS
-- saat policy di tabel profiles membaca tabel profiles itu sendiri.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin' and status = 'aktif'
  );
$$;

-- ---------------------------------------------------------------- profiles
alter table public.profiles enable row level security;

drop policy if exists "profil: baca milik sendiri atau admin" on public.profiles;
create policy "profil: baca milik sendiri atau admin"
  on public.profiles for select
  to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists "profil: admin boleh ubah" on public.profiles;
create policy "profil: admin boleh ubah"
  on public.profiles for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

-- ----------------------------------------------------------- presensi_logs
-- Policy ini hanya berpengaruh jika RLS di presensi_logs SUDAH aktif.
-- Sengaja tidak menjalankan "enable row level security" di sini, karena
-- aplikasi peserta masih menyimpan user_id = '12345' dan bisa gagal insert.
drop policy if exists "presensi: admin boleh baca semua" on public.presensi_logs;
create policy "presensi: admin boleh baca semua"
  on public.presensi_logs for select
  to authenticated
  using (public.is_admin());

-- Setelah user_id peserta memakai auth.uid(), aktifkan RLS dan tambahkan:
--
-- alter table public.presensi_logs enable row level security;
-- create policy "presensi: peserta kelola milik sendiri"
--   on public.presensi_logs for all
--   to authenticated
--   using (user_id = auth.uid()::text)
--   with check (user_id = auth.uid()::text);
