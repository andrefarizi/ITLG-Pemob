-- =============================================================================
-- SKEMA BASIS DATA POSTGRESQL & SUPABASE - ITLG MOBILE
-- =============================================================================
-- Petunjuk Penggunaan:
-- 1. Buka dashboard project Supabase Anda: https://supabase.com/dashboard
-- 2. Masuk ke menu "SQL Editor" di bilah kiri.
-- 3. Tempel (paste) seluruh isi skrip ini, lalu klik tombol "Run".
-- =============================================================================

-- 1. Aktifkan ekstensi pgcrypto untuk enkripsi kata sandi
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Tipe Data Enum untuk 4 Peran (Role) Pengguna
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('praktikan', 'aslab', 'laboran', 'dosen');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Tabel Profil Pengguna (public.profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    identifier VARCHAR(50) UNIQUE NOT NULL, -- NIM (Mahasiswa/Aslab) atau NIP/ID (Laboran/Dosen)
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    role user_role NOT NULL DEFAULT 'praktikan',
    phone VARCHAR(20),
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indeks untuk pencarian cepat berdasarkan NIM/NIP dan Email
CREATE INDEX IF NOT EXISTS idx_profiles_identifier ON public.profiles(identifier);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- 4. Pengaturan Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Kebijakan: Siapapun yang terautentikasi (atau publik saat login) bisa membaca profil
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

-- Kebijakan: Pengguna hanya bisa mengupdate profil miliknya sendiri
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- 5. Trigger Otomatis: Buat entri profil saat ada user baru di auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'identifier', split_part(new.email, '@', 1)),
        COALESCE(new.raw_user_meta_data->>'full_name', 'Pengguna Baru'),
        new.email,
        COALESCE((new.raw_user_meta_data->>'role')::user_role, 'praktikan'),
        new.raw_user_meta_data->>'phone'
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        identifier = EXCLUDED.identifier,
        role = EXCLUDED.role;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- =============================================================================
-- DATA DUMMY AWAL (4 PERAN) - Kata Sandi: password123
-- =============================================================================

DO $$
DECLARE
    uid_praktikan UUID := 'a1111111-1111-1111-1111-111111111111';
    uid_aslab     UUID := 'b2222222-2222-2222-2222-222222222222';
    uid_laboran   UUID := 'c3333333-3333-3333-3333-333333333333';
    uid_dosen     UUID := 'd4444444-4444-4444-4444-444444444444';
    encrypted_pw  TEXT;
BEGIN
    -- Hash password 'password123' dengan bcrypt standard Supabase
    encrypted_pw := crypt('password123', gen_salt('bf'));

    -- 1. MAHASISWA (PRAKTIKAN)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
        uid_praktikan, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'andreal@students.usu.ac.id', encrypted_pw, NOW(),
        '{"provider":"email","providers":["email"]}',
        '{"full_name":"Andre Al Farizi Sebayang","identifier":"241402105","role":"praktikan"}',
        NOW(), NOW(), '', '', '', ''
    ) ON CONFLICT (id) DO UPDATE SET 
        email = EXCLUDED.email,
        encrypted_password = EXCLUDED.encrypted_password,
        confirmation_token = '', recovery_token = '', email_change_token_new = '', email_change = '';

    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (
        uid_praktikan, '241402105', 'Andre Al Farizi Sebayang', 'andreal@students.usu.ac.id', 'praktikan', '081234567890'
    ) ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (uid_praktikan, uid_praktikan, format('{"sub":"%s","email":"%s"}', uid_praktikan, 'andreal@students.usu.ac.id')::jsonb, 'email', uid_praktikan::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET identity_data = EXCLUDED.identity_data;

    -- 2. ASISTEN LABORATORIUM (ASLAB)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
        uid_aslab, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'abbilrizki@students.usu.ac.id', encrypted_pw, NOW(),
        '{"provider":"email","providers":["email"]}',
        '{"full_name":"Abbil Rizki","identifier":"211402001","role":"aslab"}',
        NOW(), NOW(), '', '', '', ''
    ) ON CONFLICT (id) DO UPDATE SET 
        email = EXCLUDED.email,
        encrypted_password = EXCLUDED.encrypted_password,
        confirmation_token = '', recovery_token = '', email_change_token_new = '', email_change = '';

    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (
        uid_aslab, '211402001', 'Abbil Rizki', 'abbilrizki@students.usu.ac.id', 'aslab', '081298765432'
    ) ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (uid_aslab, uid_aslab, format('{"sub":"%s","email":"%s"}', uid_aslab, 'abbilrizki@students.usu.ac.id')::jsonb, 'email', uid_aslab::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET identity_data = EXCLUDED.identity_data;

    -- 3. LABORAN / TEKNISI
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
        uid_laboran, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'reaganbrian@students.usu.ac.id', encrypted_pw, NOW(),
        '{"provider":"email","providers":["email"]}',
        '{"full_name":"Reagan Brian","identifier":"198501012010011001","role":"laboran"}',
        NOW(), NOW(), '', '', '', ''
    ) ON CONFLICT (id) DO UPDATE SET 
        email = EXCLUDED.email,
        encrypted_password = EXCLUDED.encrypted_password,
        confirmation_token = '', recovery_token = '', email_change_token_new = '', email_change = '';

    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (
        uid_laboran, '198501012010011001', 'Reagan Brian', 'reaganbrian@students.usu.ac.id', 'laboran', '081377889900'
    ) ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (uid_laboran, uid_laboran, format('{"sub":"%s","email":"%s"}', uid_laboran, 'reaganbrian@students.usu.ac.id')::jsonb, 'email', uid_laboran::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET identity_data = EXCLUDED.identity_data;

    -- 4. DOSEN PENGAMPU
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, recovery_token, email_change_token_new, email_change
    ) VALUES (
        uid_dosen, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'danielechristian@students.usu.ac.id', encrypted_pw, NOW(),
        '{"provider":"email","providers":["email"]}',
        '{"full_name":"Dr. Eng. Daniele Christian, M.Kom.","identifier":"198705122015041002","role":"dosen"}',
        NOW(), NOW(), '', '', '', ''
    ) ON CONFLICT (id) DO UPDATE SET 
        email = EXCLUDED.email,
        encrypted_password = EXCLUDED.encrypted_password,
        confirmation_token = '', recovery_token = '', email_change_token_new = '', email_change = '';

    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (
        uid_dosen, '198705122015041002', 'Dr. Eng. Daniele Christian, M.Kom.', 'danielechristian@students.usu.ac.id', 'dosen', '081122334455'
    ) ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (uid_dosen, uid_dosen, format('{"sub":"%s","email":"%s"}', uid_dosen, 'danielechristian@students.usu.ac.id')::jsonb, 'email', uid_dosen::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET identity_data = EXCLUDED.identity_data;

END $$;
