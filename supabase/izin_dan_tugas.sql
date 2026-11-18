-- ==============================================================================
-- TABEL DAN POLICIES: IZIN/SAKIT & PENILAIAN TUGAS
-- Jalankan query ini di Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. TABEL PENGAJUAN IZIN & SAKIT
create table if not exists public.pengajuan_izin (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  jenis text not null check (jenis in ('Izin', 'Sakit')),
  tanggal_mulai date not null,
  tanggal_selesai date not null,
  alasan text not null,
  foto_url text,
  status text not null default 'menunggu' check (status in ('menunggu', 'disetujui', 'ditolak')),
  catatan_admin text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- 2. TABEL PENGUMPULAN TUGAS & PENILAIAN
create table if not exists public.pengumpulan_tugas (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  nama_divisi text not null,
  kategori text not null,
  judul text not null,
  keterangan text,
  link_hasil text,
  foto_url text,
  nilai integer check (nilai >= 0 and nilai <= 100),
  catatan_penilai text,
  status text not null default 'menunggu' check (status in ('menunggu', 'dinilai', 'revisi')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  dinilai_at timestamp with time zone
);

-- 3. ENABLE RLS
alter table public.pengajuan_izin enable row level security;
alter table public.pengumpulan_tugas enable row level security;

-- 4. POLICIES PENGAJUAN IZIN
-- Peserta & Admin boleh membaca
drop policy if exists "izin: baca milik sendiri atau admin" on public.pengajuan_izin;
create policy "izin: baca milik sendiri atau admin"
  on public.pengajuan_izin for select
  to authenticated
  using (user_id = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- Peserta boleh mengajukan izin
drop policy if exists "izin: peserta boleh ajukan" on public.pengajuan_izin;
create policy "izin: peserta boleh ajukan"
  on public.pengajuan_izin for insert
  to authenticated
  with check (user_id = auth.uid());

-- Admin boleh menyetujui / menolak izin
drop policy if exists "izin: admin boleh update status" on public.pengajuan_izin;
create policy "izin: admin boleh update status"
  on public.pengajuan_izin for update
  to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- 5. POLICIES PENGUMPULAN TUGAS
-- Peserta & Admin boleh membaca
drop policy if exists "tugas: baca milik sendiri atau admin" on public.pengumpulan_tugas;
create policy "tugas: baca milik sendiri atau admin"
  on public.pengumpulan_tugas for select
  to authenticated
  using (user_id = auth.uid() or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

-- Peserta boleh submit tugas
drop policy if exists "tugas: peserta boleh submit" on public.pengumpulan_tugas;
create policy "tugas: peserta boleh submit"
  on public.pengumpulan_tugas for insert
  to authenticated
  with check (user_id = auth.uid());

-- Admin boleh menilai tugas
drop policy if exists "tugas: admin boleh beri nilai" on public.pengumpulan_tugas;
create policy "tugas: admin boleh beri nilai"
  on public.pengumpulan_tugas for update
  to authenticated
  using (exists (select 1 from public.profiles where id = auth.uid() and role = 'admin'));

