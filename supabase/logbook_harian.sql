-- ==============================================================================
-- TABEL LOGBOOK HARIAN & POLICIES (Supabase SQL Editor)
-- Jalankan query ini di Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

create table if not exists public.logbook_harian (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  tanggal date not null,
  kegiatan text not null,
  kendala text,
  status text not null default 'menunggu' check (status in ('menunggu', 'disetujui')),
  catatan_admin text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, tanggal)
);

-- Index agar pencarian per user dan tanggal cepat
create index if not exists idx_logbook_user_tanggal on public.logbook_harian(user_id, tanggal);

-- Enable RLS
alter table public.logbook_harian enable row level security;

-- 1. SELECT: Peserta bisa baca logbook miliknya, Admin bisa baca semua
drop policy if exists "logbook: select policy" on public.logbook_harian;
drop policy if exists "logbook: baca milik sendiri atau admin" on public.logbook_harian;
create policy "logbook: select policy"
  on public.logbook_harian for select to authenticated
  using (
    user_id = auth.uid() 
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 2. INSERT: Peserta atau Admin bisa insert
drop policy if exists "logbook: insert policy" on public.logbook_harian;
drop policy if exists "logbook: peserta boleh insert" on public.logbook_harian;
create policy "logbook: insert policy"
  on public.logbook_harian for insert to authenticated
  with check (
    user_id = auth.uid() 
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- 3. UPDATE: Peserta bisa update miliknya, Admin bisa update (untuk menyetujui)
drop policy if exists "logbook: update policy" on public.logbook_harian;
drop policy if exists "logbook: peserta boleh update" on public.logbook_harian;
drop policy if exists "logbook: admin boleh update" on public.logbook_harian;
create policy "logbook: update policy"
  on public.logbook_harian for update to authenticated
  using (
    user_id = auth.uid() 
    or exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );
