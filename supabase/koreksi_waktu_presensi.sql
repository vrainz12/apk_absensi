-- ==============================================================================
-- Penyesuaian Timestamp Data Presensi (Zona Waktu WIB / UTC)
-- Menyelaraskan pencatatan waktu presensi historis pada tabel presensi_logs
-- ==============================================================================

-- 1. Koreksi data presensi hari ini atau sebelumnya yang tersimpan lompat ke depan (> sekarang)
update public.presensi_logs
set timestamp = timestamp - interval '7 hours'
where timestamp > now();

-- 2. Koreksi data presensi masuk yang tercatat di atas jam 17:00 (karena kantor tutup jam 16:00-17:00)
update public.presensi_logs
set timestamp = timestamp - interval '7 hours'
where tipe_absen ilike 'masuk'
  and extract(hour from (timestamp at time zone 'Asia/Jakarta')) >= 17;

