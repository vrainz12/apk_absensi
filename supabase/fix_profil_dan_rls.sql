-- ==============================================================================
-- Sinkronisasi ID profiles dengan auth.users dan Konfigurasi RLS
-- ==============================================================================

-- 1. Sinkronkan ID jika ada ketidakcocokan antara auth.users dan profiles
UPDATE public.profiles p
SET id = u.id
FROM auth.users u
WHERE u.email = (p.username || '@simagang.internal')
  AND p.id != u.id;

-- 2. Pastikan RLS aktif dan berikan hak baca ke authenticated user
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Hapus policy lama jika ada
DROP POLICY IF EXISTS "profil: baca milik sendiri atau admin" ON public.profiles;
DROP POLICY IF EXISTS "profil: baca semua" ON public.profiles;
DROP POLICY IF EXISTS "profil_read_policy" ON public.profiles;
DROP POLICY IF EXISTS "Allow authenticated read profiles" ON public.profiles;

-- Pasang policy baca: semua pengguna yang login boleh membaca profil
CREATE POLICY "profil: baca semua"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

-- Pasang policy update: admin atau pemilik profil boleh update
DROP POLICY IF EXISTS "profil: admin boleh ubah" ON public.profiles;
CREATE POLICY "profil: admin boleh ubah"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid() 
    OR EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Cek hasil akhir
SELECT u.id as auth_id, u.email, p.id as profile_id, p.username, p.nama, p.role, p.status
FROM auth.users u
JOIN public.profiles p ON u.id = p.id;

