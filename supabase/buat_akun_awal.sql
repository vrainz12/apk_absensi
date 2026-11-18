-- ==============================================================================
-- SCRIPT SETUP AKUN AWAL (ADMIN & PESERTA) + TABEL PROFILES
-- Jalankan script ini di Supabase Dashboard -> SQL Editor -> Run
-- ==============================================================================

-- 1. Ekstensi pgcrypto untuk hashing password
create extension if not exists pgcrypto;

-- 2. Pastikan tabel profiles memiliki kolom yang sesuai
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  nama text not null,
  role text not null default 'peserta' check (role in ('admin', 'peserta')),
  status text not null default 'aktif' check (status in ('aktif', 'nonaktif', 'selesai')),
  telepon text,
  divisi text,
  batch text,
  kampus text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ==============================================================================
-- 3. FUNGSI PEMBANTU UNTUK MEMBUAT USER LENGKAP (AUTH + PROFILE)
-- ==============================================================================
create or replace function public.create_initial_user(
  p_username text,
  p_password text,
  p_nama text,
  p_role text,
  p_divisi text default null,
  p_kampus text default null
) returns uuid as $$
declare
  v_user_id uuid;
  v_email text;
  v_encrypted_pw text;
begin
  v_email := lower(trim(p_username)) || '@simagang.internal';
  v_encrypted_pw := crypt(p_password, gen_salt('bf'));

  -- Cek apakah user sudah ada di auth.users berdasarkan email
  select id into v_user_id from auth.users where email = v_email;

  if v_user_id is null then
    v_user_id := gen_random_uuid();

    -- Masukkan ke auth.users
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change,
      phone_change,
      phone_change_token,
      created_at,
      updated_at
    ) values (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      v_email,
      v_encrypted_pw,
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('nama', p_nama, 'username', p_username),
      '',
      '',
      '',
      '',
      '',
      '',
      now(),
      now()
    );
  else
    -- Jika sudah ada, update passwordnya
    update auth.users
    set encrypted_password = v_encrypted_pw,
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        updated_at = now()
    where id = v_user_id;
  end if;

  -- Masukkan atau update ke public.profiles
  insert into public.profiles (
    id, username, nama, role, status, divisi, kampus
  ) values (
    v_user_id, lower(trim(p_username)), p_nama, p_role, 'aktif', p_divisi, p_kampus
  )
  on conflict (id) do update set
    nama = excluded.nama,
    username = excluded.username,
    role = excluded.role,
    status = 'aktif',
    divisi = coalesce(excluded.divisi, public.profiles.divisi),
    kampus = coalesce(excluded.kampus, public.profiles.kampus);

  return v_user_id;
end;
$$ language plpgsql security definer;

-- ==============================================================================
-- 4. BUAT AKUN ADMIN & AKUN PESERTA
-- ==============================================================================

-- A. AKUN ADMIN
-- Username : admin
-- Password : admin123
select public.create_initial_user(
  'admin',
  'admin123',
  'Admin Magang',
  'admin',
  'Koordinator',
  'Kantor Pusat'
);

-- B. AKUN PESERTA (CONTOH)
-- Username : zharfan
-- Password : peserta123
select public.create_initial_user(
  'zharfan',
  'peserta123',
  'Muhamad Zharfan',
  'peserta',
  'Web Development',
  'Univ. Adhirajasa'
);

-- Hapus fungsi pembantu setelah selesai agar database tetap bersih
drop function public.create_initial_user;

