-- ==============================================================================
-- Penyesuaian Atribut Akun Schema auth.users
-- Sinkronisasi default token dan role pengguna internal
-- ==============================================================================

UPDATE auth.users
SET 
  instance_id = '00000000-0000-0000-0000-000000000000',
  aud = 'authenticated',
  role = 'authenticated',
  confirmation_token = COALESCE(confirmation_token, ''),
  recovery_token = COALESCE(recovery_token, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change = COALESCE(email_change, ''),
  phone_change = COALESCE(phone_change, ''),
  phone_change_token = COALESCE(phone_change_token, '')
WHERE email LIKE '%@simagang.internal';
