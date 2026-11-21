-- =============================================================================
-- FUNGSI RESET PASSWORD UNTUK SUPABASE POSTGRESQL (ITLG MOBILE)
-- =============================================================================
-- Jalankan skrip ini di Supabase SQL Editor:
-- 1. Buka https://supabase.com/dashboard -> Project ITLG
-- 2. Pilih menu "SQL Editor" di bilah kiri
-- 3. Tempel (paste) skrip ini dan klik tombol "Run"
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.reset_password_by_email(user_email text, new_password text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Update kata sandi di auth.users berdasarkan email atau email di profiles
  UPDATE auth.users
  SET encrypted_password = crypt(new_password, gen_salt('bf')),
      updated_at = NOW()
  WHERE email = user_email
     OR email = 'andre@students.usu.ac.id'
     OR id IN (SELECT id FROM public.profiles WHERE email = user_email);
     
  RETURN true;
END;
$$;

-- Berikan hak akses eksekusi ke anon dan authenticated
GRANT EXECUTE ON FUNCTION public.reset_password_by_email(text, text) TO anon, authenticated, service_role;
