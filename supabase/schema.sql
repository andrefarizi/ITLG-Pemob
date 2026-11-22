-- =============================================================================
-- MASTER DATABASE SCHEMA ALL-IN-ONE (POSTGRESQL & SUPABASE) - ITLG MOBILE
-- =============================================================================
-- File ini menggabungkan SELURUH skema database, autentikasi 4 role, fungsi RPC,
-- storage bucket, kebijakan RLS, Supabase Realtime, dan seed data awal.
--
-- CARA PENGGUNAAN (CUKUP JALANKAN 1 FILE INI SAJA):
-- 1. Buka Dashboard Supabase: https://supabase.com/dashboard
-- 2. Masuk ke menu "SQL Editor" -> klik "New query".
-- 3. Salin (Copy) dan Tempel (Paste) seluruh isi file `supabase/schema.sql` ini.
-- 4. Klik tombol "Run" (Ctrl + Enter).
-- =============================================================================

-- =============================================================================
-- BAGIAN 1: EKSTENSI, TIPE ENUM, PROFIL PENGGUNA, AUTH 4 ROLE & RESET PASSWORD
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('praktikan', 'aslab', 'laboran', 'dosen');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

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

CREATE INDEX IF NOT EXISTS idx_profiles_identifier ON public.profiles(identifier);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE USING (true) WITH CHECK (true);

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
        email = EXCLUDED.email,
        role = EXCLUDED.role;
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Fungsi RPC Reset Password via OTP Email
CREATE OR REPLACE FUNCTION public.reset_password_by_email(user_email text, new_password text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE auth.users
  SET encrypted_password = crypt(new_password, gen_salt('bf')),
      updated_at = NOW()
  WHERE lower(email) = lower(user_email)
     OR id IN (SELECT id FROM public.profiles WHERE lower(email) = lower(user_email));
  RETURN true;
END;
$$;

GRANT EXECUTE ON FUNCTION public.reset_password_by_email(text, text) TO anon, authenticated, service_role;

-- Seed 4 Akun Utama (Praktikan, Aslab, Laboran, Dosen) - Password: password123
DO $$
DECLARE
    uid_praktikan UUID := 'a1111111-1111-1111-1111-111111111111';
    uid_aslab     UUID := 'b2222222-2222-2222-2222-222222222222';
    uid_laboran   UUID := 'c3333333-3333-3333-3333-333333333333';
    uid_dosen     UUID := 'd4444444-4444-4444-4444-444444444444';
    encrypted_pw  TEXT;
BEGIN
    encrypted_pw := crypt('password123', gen_salt('bf'));

    -- 1. MAHASISWA (PRAKTIKAN) - NIM: 241402105
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
    VALUES (uid_praktikan, '241402105', 'Andre Al Farizi Sebayang', 'andreal@students.usu.ac.id', 'praktikan', '081234567890')
    ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (uid_praktikan, uid_praktikan, format('{"sub":"%s","email":"%s"}', uid_praktikan, 'andreal@students.usu.ac.id')::jsonb, 'email', uid_praktikan::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET identity_data = EXCLUDED.identity_data;

    -- 2. ASISTEN LABORATORIUM (ASLAB) - NIM: 211402001
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
    VALUES (uid_aslab, '211402001', 'Abbil Rizki', 'abbilrizki@students.usu.ac.id', 'aslab', '081298765432')
    ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (uid_aslab, uid_aslab, format('{"sub":"%s","email":"%s"}', uid_aslab, 'abbilrizki@students.usu.ac.id')::jsonb, 'email', uid_aslab::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET identity_data = EXCLUDED.identity_data;

    -- 3. LABORAN / TEKNISI - NIP: 198501012010011001
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
    VALUES (uid_laboran, '198501012010011001', 'Reagan Brian', 'reaganbrian@students.usu.ac.id', 'laboran', '081377889900')
    ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (uid_laboran, uid_laboran, format('{"sub":"%s","email":"%s"}', uid_laboran, 'reaganbrian@students.usu.ac.id')::jsonb, 'email', uid_laboran::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET identity_data = EXCLUDED.identity_data;

    -- 4. DOSEN PENGAMPU - NIP: 198705122015041002
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
    VALUES (uid_dosen, '198705122015041002', 'Dr. Eng. Daniele Christian, M.Kom.', 'danielechristian@students.usu.ac.id', 'dosen', '081122334455')
    ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (uid_dosen, uid_dosen, format('{"sub":"%s","email":"%s"}', uid_dosen, 'danielechristian@students.usu.ac.id')::jsonb, 'email', uid_dosen::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE SET identity_data = EXCLUDED.identity_data;
END $$;

-- Pastikan kolom token GoTrue tidak NULL untuk mencegah error 500 saat login
UPDATE auth.users
SET confirmation_token = COALESCE(confirmation_token, ''),
    recovery_token = COALESCE(recovery_token, ''),
    email_change_token_new = COALESCE(email_change_token_new, ''),
    email_change = COALESCE(email_change, ''),
    email_change_token_current = COALESCE(email_change_token_current, ''),
    phone_change = COALESCE(phone_change, ''),
    phone_change_token = COALESCE(phone_change_token, '')
WHERE confirmation_token IS NULL
   OR recovery_token IS NULL
   OR email_change_token_new IS NULL
   OR email_change IS NULL;

-- =============================================================================
-- BAGIAN 2: PRAKTIKUM (4 MATA KULIAH), PERTEMUAN, TUGAS, KUIS & RATING ASISTEN
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.praktikum_courses (
    id TEXT PRIMARY KEY,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    semester TEXT NOT NULL DEFAULT 'Semester Ganjil 2026/2027',
    asisten_name TEXT NOT NULL,
    asisten_initials TEXT NOT NULL,
    room TEXT NOT NULL,
    jadwal_daftar TEXT NOT NULL,
    jadwal_detail TEXT NOT NULL,
    jadwal_absensi TEXT NOT NULL,
    jam TEXT NOT NULL,
    current_module_num INT NOT NULL DEFAULT 4,
    total_meetings INT NOT NULL DEFAULT 12,
    modul_title TEXT NOT NULL,
    modul_desc TEXT NOT NULL,
    materi_title TEXT NOT NULL,
    materi_file TEXT NOT NULL,
    tugas_title TEXT NOT NULL,
    tugas_deadline TEXT NOT NULL DEFAULT 'Batas 10:30 WIB, 29 Sep 2026',
    pre_test_title TEXT NOT NULL,
    post_test_title TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.praktikum_meetings (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL REFERENCES public.praktikum_courses(id) ON DELETE CASCADE,
    meeting_number INT NOT NULL,
    module_title TEXT NOT NULL,
    date_label TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    materi_title TEXT NOT NULL DEFAULT '',
    materi_file TEXT NOT NULL DEFAULT '',
    tugas_title TEXT NOT NULL DEFAULT '',
    tugas_deadline TEXT NOT NULL DEFAULT 'Batas 10:30 WIB, 29 Sep 2026',
    kuis_title TEXT NOT NULL DEFAULT '',
    attend_status TEXT NOT NULL DEFAULT 'hadir' CHECK (attend_status IN ('upcoming', 'hadir', 'izin', 'pending')),
    attend_note_icon TEXT,
    attend_note TEXT,
    izin_file TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (course_id, meeting_number)
);

CREATE INDEX IF NOT EXISTS idx_praktikum_meetings_course ON public.praktikum_meetings(course_id, meeting_number);

CREATE TABLE IF NOT EXISTS public.tugas_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL REFERENCES public.praktikum_courses(id) ON DELETE CASCADE,
    meeting_number INT NOT NULL,
    user_identifier TEXT NOT NULL,
    user_name TEXT NOT NULL,
    files_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    repo_url TEXT NOT NULL DEFAULT '',
    note TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'graded', 'cancelled')),
    score INT,
    feedback TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (course_id, meeting_number, user_identifier)
);

CREATE INDEX IF NOT EXISTS idx_tugas_submissions_course ON public.tugas_submissions(course_id, meeting_number);

CREATE TABLE IF NOT EXISTS public.kuis_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL REFERENCES public.praktikum_courses(id) ON DELETE CASCADE,
    meeting_number INT NOT NULL,
    user_identifier TEXT NOT NULL,
    user_name TEXT NOT NULL,
    answers_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    score INT NOT NULL DEFAULT 0,
    correct_count INT NOT NULL DEFAULT 0,
    wrong_count INT NOT NULL DEFAULT 0,
    duration_seconds INT NOT NULL DEFAULT 0,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (course_id, meeting_number, user_identifier)
);

CREATE TABLE IF NOT EXISTS public.asisten_ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL REFERENCES public.praktikum_courses(id) ON DELETE CASCADE,
    asisten_name TEXT NOT NULL,
    user_identifier TEXT NOT NULL,
    rating_materi INT NOT NULL CHECK (rating_materi BETWEEN 1 AND 5),
    rating_penjelasan INT NOT NULL CHECK (rating_penjelasan BETWEEN 1 AND 5),
    rating_waktu INT NOT NULL CHECK (rating_waktu BETWEEN 1 AND 5),
    rating_kesigapan INT NOT NULL CHECK (rating_kesigapan BETWEEN 1 AND 5),
    comment TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (course_id, user_identifier)
);

INSERT INTO public.praktikum_courses (
    id, code, name, semester, asisten_name, asisten_initials, room,
    jadwal_daftar, jadwal_detail, jadwal_absensi, jam,
    current_module_num, total_meetings,
    modul_title, modul_desc, materi_title, materi_file,
    tugas_title, tugas_deadline, pre_test_title, post_test_title, sort_order
) VALUES
(
    'pemob', 'TIF 3001 - Kelas C', 'Pemrograman Mobile', 'Semester Ganjil 2026/2027',
    'Andi Pratama', 'AP', 'Lab Komputer 1',
    'Sen, 08:00–09:40', 'Sen, 08:00-09:40', 'Sen, 08:00–09:40', '08:00–09:40 WIB',
    4, 12,
    'State Management',
    'Pembahasan State Management Flutter secara mendalam: setState, ChangeNotifier, dan Provider.',
    'Panduan State Management Flutter', 'Panduan_State_Management_Flutter.pdf',
    'Tugas 4 : Implementasi State Management', 'Batas 10:30 WIB, 29 Sep 2026',
    'Pre-Test Modul 4 : State Management', 'Post-Test Modul 4 : State Management', 1
),
(
    'desain', 'TIF 3002 - Kelas C', 'Desain Interaksi', 'Semester Ganjil 2026/2027',
    'Feri Gunawan', 'FG', 'Lab Jaringan 2',
    'Sen, 13:00–14:40', 'Sen, 13:00-14:40', 'Sen, 13:00–14:40', '13:00–14:40 WIB',
    4, 12,
    'Figma Management',
    'Pembahasan pengelolaan file Figma secara mendalam: komponen, variant, dan auto layout.',
    'Panduan Penggunaan Figma', 'Panduan_Penggunaan_Figma.pdf',
    'Tugas 4 : Pembuatan Prototype Figma', 'Batas 10:30 WIB, 29 Sep 2026',
    'Pre-Test Modul 4 : Figma Management', 'Post-Test Modul 4 : Figma Management', 2
),
(
    'adj', 'TIF 3003 - Kelas C', 'Analisis Desain Jaringan', 'Semester Ganjil 2026/2027',
    'Sinta Marpaung', 'SM', 'Lab Jaringan 1',
    'Rab, 10:00–11:40', 'Rab, 10:00-11:40', 'Rab, 10:00–11:40', '10:00–11:40 WIB',
    4, 12,
    'VLAN & Inter-VLAN Routing',
    'Perancangan segmentasi VLAN, trunking 802.1Q, dan konfigurasi Router-on-a-Stick pada Cisco Packet Tracer.',
    'Panduan Konfigurasi VLAN & Trunking', 'Panduan_VLAN_InterVLAN_Routing.pdf',
    'Tugas 4 : Topologi Multi-VLAN Kampus', 'Batas 10:30 WIB, 01 Okt 2026',
    'Pre-Test Modul 4 : VLAN & Routing', 'Post-Test Modul 4 : VLAN & Routing', 3
),
(
    'ml', 'TIF 3004 - Kelas C', 'Machine Learning', 'Semester Ganjil 2026/2027',
    'Rizky Harahap', 'RH', 'Lab AI & Data',
    'Kam, 13:00–14:40', 'Kam, 13:00-14:40', 'Kam, 13:00–14:40', '13:00–14:40 WIB',
    4, 12,
    'Klasifikasi Supervised Learning',
    'Implementasi algoritma Decision Tree, Random Forest, dan evaluasi confusion matrix menggunakan scikit-learn.',
    'Panduan Klasifikasi Supervised ML', 'Panduan_Klasifikasi_ScikitLearn.pdf',
    'Tugas 4 : Model Klasifikasi Dataset Medis', 'Batas 10:30 WIB, 02 Okt 2026',
    'Pre-Test Modul 4 : Klasifikasi ML', 'Post-Test Modul 4 : Klasifikasi ML', 4
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.praktikum_meetings (
    id, course_id, meeting_number, module_title, date_label, description,
    materi_title, materi_file, tugas_title, tugas_deadline, kuis_title,
    attend_status, attend_note_icon, attend_note, izin_file
) VALUES
('pemob-m5', 'pemob', 5, 'Modul 5 • Navigasi & Routing', 'Sen, 05 Okt 2026 • 08:00–09:40 WIB', 'Penerapan Navigator, Named Routes, dan pengiriman argumen antar halaman.', 'Panduan Navigasi Flutter', 'Modul_5_Navigasi.pdf', 'Tugas 5 : Aplikasi Multi Halaman', 'Batas 10:30 WIB, 12 Okt 2026', 'Pre-Test Modul 5 : Navigasi', 'upcoming', NULL, NULL, NULL),
('pemob-m4', 'pemob', 4, 'Modul 4 • State Management', 'Sen, 28 Sep 2026 • 08:00–09:40 WIB', 'Pembahasan State Management Flutter secara mendalam: setState, ChangeNotifier, dan Provider.', 'Panduan State Management Flutter', 'Panduan_State_Management_Flutter.pdf', 'Tugas 4 : Implementasi State Management', 'Batas 10:30 WIB, 29 Sep 2026', 'Pre-Test Modul 4 : State Management', 'hadir', 'qrcode', 'Tercatat 08:03 WIB melalui pindai QR', NULL),
('pemob-m3', 'pemob', 3, 'Modul 3 • Layout & Navigasi', 'Sen, 21 Sep 2026 • 08:00–09:40 WIB', 'Penyusunan layout responsif dengan Row, Column, Stack, dan ListView.', 'Materi Layout & Navigasi', 'Modul_3_Layout.pdf', 'Tugas 3 : Halaman Login', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 08:01 WIB melalui tombol hadir & lokasi', NULL),
('pemob-m2', 'pemob', 2, 'Modul 2 • Widget Dasar', 'Sen, 14 Sep 2026 • 08:00–09:40 WIB', 'Pengenalan StatelessWidget, StatefulWidget, dan komponen UI dasar.', 'Materi Widget Dasar', 'Modul_2_Widget.pdf', 'Tugas 2 : Profil Mahasiswa', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'izin', NULL, NULL, 'surat_dokter.pdf'),
('pemob-m1', 'pemob', 1, 'Modul 1 • Pengenalan Flutter', 'Sen, 07 Sep 2026 • 08:00–09:40 WIB', 'Instalasi Flutter SDK, emulator Android, dan struktur proyek Dart.', 'Materi Pengenalan Flutter', 'Modul_1_Flutter.pdf', 'Tugas 1 : Hello Flutter', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 07:58 WIB melalui pindai QR', NULL),

('desain-m5', 'desain', 5, 'Modul 5 • Design System', 'Sen, 05 Okt 2026 • 13:00–14:40 WIB', 'Membangun token warna, tipografi, dan pustaka komponen terstandar.', 'Panduan Design System', 'Modul_5_Design_System.pdf', 'Tugas 5 : Design System Mini', 'Batas 10:30 WIB, 12 Okt 2026', 'Pre-Test Modul 5 : Design System', 'upcoming', NULL, NULL, NULL),
('desain-m4', 'desain', 4, 'Modul 4 • Figma Management', 'Sen, 28 Sep 2026 • 13:00–14:40 WIB', 'Pembahasan materi Figma secara mendalam: komponen, variant, dan auto layout.', 'Panduan Penggunaan Figma', 'Panduan_Penggunaan_Figma.pdf', 'Tugas 4 : Pembuatan Prototype Figma', 'Batas 10:30 WIB, 29 Sep 2026', 'Pre-Test Modul 4 : Figma Management', 'hadir', 'qrcode', 'Tercatat 13:02 WIB melalui pindai QR', NULL),
('desain-m3', 'desain', 3, 'Modul 3 • Prototyping Dasar', 'Sen, 21 Sep 2026 • 13:00–14:40 WIB', 'Membuat alur interaksi interaktif dan transisi smart animate.', 'Materi Prototyping Dasar', 'Modul_3_Prototyping.pdf', 'Tugas 3 : Alur Login Interaktif', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 13:00 WIB melalui tombol hadir & lokasi', NULL),
('desain-m2', 'desain', 2, 'Modul 2 • Wireframing', 'Sen, 14 Sep 2026 • 13:00–14:40 WIB', 'Perancangan wireframe low-fidelity dan hierarki informasi.', 'Materi Wireframing', 'Modul_2_Wireframing.pdf', 'Tugas 2 : Wireframe Aplikasi Kampus', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'hadir', 'qrcode', 'Tercatat 12:58 WIB melalui pindai QR', NULL),
('desain-m1', 'desain', 1, 'Modul 1 • Pengenalan Figma', 'Sen, 07 Sep 2026 • 13:00–14:40 WIB', 'Pengenalan workspace Figma, frame, grid, dan constraints.', 'Materi Pengenalan Figma', 'Modul_1_Figma.pdf', 'Tugas 1 : Eksplorasi Frame Figma', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 13:01 WIB melalui pindai QR', NULL),

('adj-m5', 'adj', 5, 'Modul 5 • Dynamic Routing OSPF', 'Rab, 07 Okt 2026 • 10:00–11:40 WIB', 'Konfigurasi routing dinamis OSPF single-area dan verifikasi neighbor table.', 'Panduan Routing OSPF', 'Modul_5_OSPF.pdf', 'Tugas 5 : Simulasi OSPF Multi-Router', 'Batas 10:30 WIB, 14 Okt 2026', 'Pre-Test Modul 5 : OSPF', 'upcoming', NULL, NULL, NULL),
('adj-m4', 'adj', 4, 'Modul 4 • VLAN & Inter-VLAN Routing', 'Rab, 30 Sep 2026 • 10:00–11:40 WIB', 'Perancangan segmentasi VLAN, trunking 802.1Q, dan Router-on-a-Stick.', 'Panduan Konfigurasi VLAN & Trunking', 'Panduan_VLAN_InterVLAN_Routing.pdf', 'Tugas 4 : Topologi Multi-VLAN Kampus', 'Batas 10:30 WIB, 01 Okt 2026', 'Pre-Test Modul 4 : VLAN & Routing', 'hadir', 'qrcode', 'Tercatat 10:02 WIB melalui pindai QR', NULL),
('adj-m3', 'adj', 3, 'Modul 3 • Subnetting & VLSM', 'Rab, 23 Sep 2026 • 10:00–11:40 WIB', 'Perhitungan alamat IPv4, CIDR, dan efisiensi pembagian blok VLSM.', 'Materi Subnetting & VLSM', 'Modul_3_VLSM.pdf', 'Tugas 3 : Desain Alokasi IP Gedung', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 10:01 WIB melalui tombol hadir & lokasi', NULL),
('adj-m2', 'adj', 2, 'Modul 2 • Topologi & Analisis Trafik', 'Rab, 16 Sep 2026 • 10:00–11:40 WIB', 'Pemetaan kebutuhan bandwidth, topologi hirarkis, dan inspeksi Wireshark.', 'Materi Topologi & Wireshark', 'Modul_2_Trafik.pdf', 'Tugas 2 : Capture Paket Wireshark', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'hadir', 'qrcode', 'Tercatat 09:59 WIB melalui pindai QR', NULL),
('adj-m1', 'adj', 1, 'Modul 1 • Pengenalan Desain Jaringan', 'Rab, 09 Sep 2026 • 10:00–11:40 WIB', 'Model OSI, TCP/IP, dan simulasi jaringan dasar di Packet Tracer.', 'Materi Pengenalan Jaringan', 'Modul_1_Jaringan.pdf', 'Tugas 1 : Simulasi LAN Dasar', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 10:00 WIB melalui pindai QR', NULL),

('ml-m5', 'ml', 5, 'Modul 5 • Clustering & Unsupervised', 'Kam, 08 Okt 2026 • 13:00–14:40 WIB', 'Penerapan K-Means, Elbow Method, dan Silhouette Score untuk segmentasi data.', 'Panduan K-Means Clustering', 'Modul_5_Clustering.pdf', 'Tugas 5 : Segmentasi Pelanggan', 'Batas 10:30 WIB, 15 Okt 2026', 'Pre-Test Modul 5 : Clustering', 'upcoming', NULL, NULL, NULL),
('ml-m4', 'ml', 4, 'Modul 4 • Klasifikasi Supervised Learning', 'Kam, 01 Okt 2026 • 13:00–14:40 WIB', 'Implementasi Decision Tree, Random Forest, dan evaluasi confusion matrix dengan scikit-learn.', 'Panduan Klasifikasi Supervised ML', 'Panduan_Klasifikasi_ScikitLearn.pdf', 'Tugas 4 : Model Klasifikasi Dataset Medis', 'Batas 10:30 WIB, 02 Okt 2026', 'Pre-Test Modul 4 : Klasifikasi ML', 'hadir', 'qrcode', 'Tercatat 13:03 WIB melalui pindai QR', NULL),
('ml-m3', 'ml', 3, 'Modul 3 • Regresi Linear & Logistik', 'Kam, 24 Sep 2026 • 13:00–14:40 WIB', 'Pemodelan prediksi kontinu dengan Linear Regression dan evaluasi MSE/R2.', 'Materi Regresi Linear', 'Modul_3_Regresi.pdf', 'Tugas 3 : Prediksi Harga Properti', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 13:01 WIB melalui tombol hadir & lokasi', NULL),
('ml-m2', 'ml', 2, 'Modul 2 • Preprocessing & EDA', 'Kam, 17 Sep 2026 • 13:00–14:40 WIB', 'Pembersihan missing values, encoding fitur kategorikal, dan scaling data.', 'Materi Preprocessing Data', 'Modul_2_EDA.pdf', 'Tugas 2 : Pipeline Preprocessing', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'hadir', 'qrcode', 'Tercatat 12:59 WIB melalui pindai QR', NULL),
('ml-m1', 'ml', 1, 'Modul 1 • Pengenalan Python & NumPy', 'Kam, 10 Sep 2026 • 13:00–14:40 WIB', 'Manipulasi array NumPy, DataFrame Pandas, dan visualisasi Matplotlib.', 'Materi Python untuk ML', 'Modul_1_Python_ML.pdf', 'Tugas 1 : Eksplorasi Dataset CSV', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 13:00 WIB melalui pindai QR', NULL)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- BAGIAN 3: PRESENSI (SESI AKTIF, QR DINAMIS 5 MENIT, REKAMAN GPS & IZIN)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.attendance_sessions (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL DEFAULT 'pemob',
    meeting_number INT NOT NULL DEFAULT 5,
    lab_name TEXT NOT NULL DEFAULT 'Lab Komputer 1',
    lat DOUBLE PRECISION NOT NULL DEFAULT 3.5621,
    lng DOUBLE PRECISION NOT NULL DEFAULT 98.6600,
    radius_m DOUBLE PRECISION NOT NULL DEFAULT 50.0,
    allow_qr BOOLEAN NOT NULL DEFAULT TRUE,
    allow_button BOOLEAN NOT NULL DEFAULT TRUE,
    require_signature BOOLEAN NOT NULL DEFAULT TRUE,
    duration_minutes INT NOT NULL DEFAULT 15,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'closed')),
    qr_token TEXT,
    qr_expires_at TIMESTAMPTZ,
    started_by TEXT NOT NULL DEFAULT 'Andi Pratama',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ
);

ALTER TABLE public.attendance_sessions ADD COLUMN IF NOT EXISTS qr_token TEXT;
ALTER TABLE public.attendance_sessions ADD COLUMN IF NOT EXISTS qr_expires_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.attendance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL,
    meeting_number INT NOT NULL,
    user_identifier TEXT NOT NULL,
    user_name TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('hadir', 'izin', 'alpa', 'pending')),
    method TEXT NOT NULL DEFAULT 'qr' CHECK (method IN ('qr', 'location', 'manual', 'izin')),
    note TEXT NOT NULL DEFAULT '',
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    distance_m DOUBLE PRECISION,
    has_signature BOOLEAN NOT NULL DEFAULT TRUE,
    updated_by TEXT,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (course_id, meeting_number, user_identifier)
);

CREATE INDEX IF NOT EXISTS idx_attendance_records_course ON public.attendance_records(course_id, meeting_number);
CREATE INDEX IF NOT EXISTS idx_attendance_records_user ON public.attendance_records(user_identifier);

CREATE TABLE IF NOT EXISTS public.leave_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL,
    meeting_number INT NOT NULL,
    user_identifier TEXT NOT NULL,
    user_name TEXT NOT NULL,
    leave_type TEXT NOT NULL,
    pertemuan_label TEXT NOT NULL,
    note TEXT NOT NULL,
    file_name TEXT,
    status INT NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2)),
    decided_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON public.leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_user ON public.leave_requests(user_identifier);

INSERT INTO public.attendance_sessions (
    id, course_id, meeting_number, lab_name, lat, lng, radius_m,
    allow_qr, allow_button, require_signature, duration_minutes, status, started_by
) VALUES (
    'pemob-p5', 'pemob', 5, 'Lab Komputer 1', 3.5621, 98.6600, 50.0,
    TRUE, TRUE, TRUE, 15, 'active', 'Andi Pratama'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.attendance_records (
    course_id, meeting_number, user_identifier, user_name, status, method, note, has_signature
) VALUES
    ('pemob', 4, '231402045', 'Rina Novita', 'hadir', 'location', 'Tombol + Lokasi • 08:02', TRUE),
    ('pemob', 4, '231402051', 'Dimas Saputra', 'hadir', 'manual', 'Diubah manual oleh asisten • tanpa tanda tangan', FALSE),
    ('pemob', 4, '231402063', 'Maya Hutagalung', 'izin', 'izin', 'Izin Sakit disetujui asisten', FALSE),
    ('pemob', 4, '231402070', 'Yoga Siregar', 'alpa', 'manual', 'Tidak hadir tanpa keterangan', FALSE),
    ('pemob', 4, '231402082', 'Lia Nasution', 'izin', 'izin', 'Izin Keluarga disetujui asisten', FALSE),
    ('pemob', 5, '231402045', 'Rina Novita', 'hadir', 'qr', 'QR • 08:02', TRUE),
    ('pemob', 5, '231402051', 'Dimas Saputra', 'hadir', 'location', 'Tombol • 08:03', TRUE),
    ('pemob', 5, '231402063', 'Maya Hutagalung', 'hadir', 'qr', 'QR • 08:05', TRUE)
ON CONFLICT (course_id, meeting_number, user_identifier) DO NOTHING;

INSERT INTO public.leave_requests (
    course_id, meeting_number, user_identifier, user_name,
    leave_type, pertemuan_label, note, file_name, status
) VALUES
(
    'pemob', 5, '231402045', 'Rina Novita',
    'Izin Sakit', '5 • Sen, 05 Okt',
    'Demam dan disarankan beristirahat oleh dokter klinik kampus.',
    'surat_dokter.pdf', 0
),
(
    'pemob', 4, '231402051', 'Dimas Saputra',
    'Kendala Perangkat', '4 • Sen, 28 Sep',
    'Kamera ponsel rusak sehingga tidak dapat memindai QR. Saya hadir di Lab Komputer 1.',
    NULL, 0
)
ON CONFLICT DO NOTHING;

-- =============================================================================
-- BAGIAN 4: MEJA LAB, BOOKING MEJA, TIKET KERUSAKAN & INVENTARIS SOFTWARE
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.lab_desks (
    id BIGSERIAL PRIMARY KEY,
    lab_name TEXT NOT NULL,
    desk_number INT NOT NULL,
    pc_code TEXT NOT NULL,
    spec TEXT NOT NULL DEFAULT 'Core i5-12400 • 16 GB • SSD 512 GB',
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'taken', 'broken')),
    booked_by_user_id TEXT,
    booked_by_name TEXT,
    booked_at TIMESTAMPTZ,
    session_key TEXT NOT NULL DEFAULT 'PEMOB-PERTEMUAN-5',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (lab_name, desk_number)
);

CREATE INDEX IF NOT EXISTS idx_lab_desks_lab ON public.lab_desks(lab_name);
CREATE INDEX IF NOT EXISTS idx_lab_desks_status ON public.lab_desks(lab_name, status);

CREATE TABLE IF NOT EXISTS public.desk_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_name TEXT NOT NULL,
    desk_number INT NOT NULL,
    session_key TEXT NOT NULL DEFAULT 'PEMOB-PERTEMUAN-5',
    user_id TEXT,
    user_identifier TEXT,
    user_name TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'released')),
    booked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_desk_bookings_session ON public.desk_bookings(lab_name, session_key);

CREATE TABLE IF NOT EXISTS public.lab_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_code TEXT UNIQUE NOT NULL,
    lab_name TEXT NOT NULL,
    desk_number INT,
    pc_code TEXT,
    icon TEXT NOT NULL DEFAULT 'desktop_device',
    category TEXT NOT NULL DEFAULT 'PC / Monitor',
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    reporter_id TEXT,
    reporter_name TEXT NOT NULL,
    reporter_role TEXT NOT NULL DEFAULT 'praktikan' CHECK (reporter_role IN ('praktikan', 'aslab', 'laboran')),
    photo_name TEXT NOT NULL DEFAULT 'foto_kendala.jpg',
    status INT NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2)),
    handling_note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lab_tickets_lab_desk ON public.lab_tickets(lab_name, desk_number);
CREATE INDEX IF NOT EXISTS idx_lab_tickets_status ON public.lab_tickets(status);

CREATE TABLE IF NOT EXISTS public.lab_software (
    id BIGSERIAL PRIMARY KEY,
    lab_name TEXT NOT NULL,
    software_name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'code_tags',
    is_installed BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (lab_name, software_name)
);

CREATE INDEX IF NOT EXISTS idx_lab_software_lab ON public.lab_software(lab_name);

INSERT INTO public.lab_desks (lab_name, desk_number, pc_code, spec, status, booked_by_user_id, booked_by_name, booked_at)
SELECT
    'Lab Komputer 1',
    n,
    'PC-' || LPAD(n::text, 2, '0'),
    'Core i5-12400 • 16 GB • SSD 512 GB',
    CASE
        WHEN n IN (3, 8, 14, 17, 25, 27, 30) THEN 'available'
        WHEN n = 23 THEN 'broken'
        ELSE 'taken'
    END,
    CASE WHEN n = 12 THEN '231402045' ELSE NULL END,
    CASE
        WHEN n = 12 THEN 'Rina Novita'
        WHEN n NOT IN (3, 8, 14, 17, 25, 27, 30, 23) THEN 'Praktikan Sesi Aktif'
        ELSE NULL
    END,
    CASE WHEN n NOT IN (3, 8, 14, 17, 25, 27, 30, 23) THEN NOW() ELSE NULL END
FROM generate_series(1, 30) AS n
ON CONFLICT (lab_name, desk_number) DO NOTHING;

INSERT INTO public.lab_desks (lab_name, desk_number, pc_code, spec, status) VALUES
    ('Lab Jaringan 2', 1, 'PC-01', 'Core i5-12400 • 16 GB • SSD 512 GB', 'available'),
    ('Lab Jaringan 2', 2, 'PC-02', 'Core i5-12400 • 16 GB • SSD 512 GB', 'available'),
    ('Lab Jaringan 2', 12, 'PC-12', 'Core i5-12400 • 16 GB • SSD 512 GB', 'broken'),
    ('Lab Multimedia', 1, 'PC-01', 'Core i5-12400 • 16 GB • SSD 512 GB', 'available'),
    ('Lab Multimedia', 2, 'PC-02', 'Core i5-12400 • 16 GB • SSD 512 GB', 'available'),
    ('Lab Multimedia', 12, 'PC-12', 'Core i5-12400 • 16 GB • SSD 512 GB', 'broken')
ON CONFLICT (lab_name, desk_number) DO NOTHING;

INSERT INTO public.lab_tickets (
    ticket_code, lab_name, desk_number, pc_code, icon, category,
    title, description, reporter_name, reporter_role, photo_name, status, handling_note
) VALUES
(
    '#TK-0921', 'Lab Komputer 1', 12, 'PC-12', 'desktop_device', 'PC • Meja 12',
    'PC-12 tidak dapat menyala',
    'Layar tetap hitam setelah tombol power ditekan dan lampu indikator tidak menyala. Kabel daya sudah dicoba di stopkontak lain.',
    'Andi Pratama', 'aslab', 'foto_pc12.jpg', 0,
    'Power supply diganti, menunggu pengujian ulang.'
),
(
    '#TK-0920', 'Lab Jaringan 2', NULL, NULL, 'projector', 'Proyektor',
    'Proyektor buram',
    'Tampilan proyektor tidak fokus dan warna pudar saat presentasi modul.',
    'Feri Gunawan', 'aslab', 'foto_proyektor.jpg', 0, ''
),
(
    '#TK-0918', 'Lab Multimedia', NULL, NULL, 'wifi', 'Jaringan',
    'Koneksi jaringan putus',
    'Tiga PC di baris belakang tidak mendapat alamat IP.',
    'Sinta Marpaung', 'aslab', 'foto_jaringan.jpg', 0, ''
)
ON CONFLICT (ticket_code) DO NOTHING;

INSERT INTO public.lab_software (lab_name, software_name, icon, is_installed) VALUES
    ('Lab Komputer 1', 'MySQL 8.0', 'database_outline', true),
    ('Lab Komputer 1', 'PostgreSQL 16', 'database_outline', true),
    ('Lab Komputer 1', 'Android Studio', 'code_tags', false),
    ('Lab Komputer 1', 'Visual Studio Code', 'code_tags', true),
    ('Lab Komputer 1', 'Figma Desktop', 'pencil', true),
    ('Lab Jaringan 2', 'Cisco Packet Tracer', 'wifi', true),
    ('Lab Jaringan 2', 'Wireshark', 'wifi', true),
    ('Lab Jaringan 2', 'PuTTY / OpenSSH', 'code_tags', true),
    ('Lab Jaringan 2', 'VirtualBox', 'desktop_device', true),
    ('Lab Jaringan 2', 'GNS3', 'wifi', false),
    ('Lab Multimedia', 'Figma Desktop', 'pencil', true),
    ('Lab Multimedia', 'Blender 4.2', 'desktop_device', true),
    ('Lab Multimedia', 'Visual Studio Code', 'code_tags', true),
    ('Lab Multimedia', 'Unity Hub', 'code_tags', false),
    ('Lab Multimedia', 'OBS Studio', 'camera', true)
ON CONFLICT (lab_name, software_name) DO NOTHING;

-- =============================================================================
-- BAGIAN 5: JADWAL PRAKTIKUM, PENGUMUMAN & APPROVAL PEMINJAMAN RUANGAN
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.praktikum_schedules (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    course_name TEXT NOT NULL,
    kelas TEXT NOT NULL DEFAULT 'Kelas C',
    day_index INT NOT NULL CHECK (day_index BETWEEN 0 AND 5),
    day_short TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    room TEXT NOT NULL,
    asisten TEXT NOT NULL,
    week_number INT NOT NULL DEFAULT 4,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_praktikum_schedules_day ON public.praktikum_schedules(day_index);
CREATE INDEX IF NOT EXISTS idx_praktikum_schedules_course ON public.praktikum_schedules(course_id);

CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT,
    category INT NOT NULL DEFAULT 1 CHECK (category IN (1, 2, 3)),
    tag TEXT NOT NULL DEFAULT 'Perubahan Jadwal',
    tag_red BOOLEAN NOT NULL DEFAULT TRUE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    author TEXT NOT NULL,
    old_schedule TEXT,
    new_schedule TEXT,
    room TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_announcements_created ON public.announcements(created_at DESC);

CREATE TABLE IF NOT EXISTS public.room_booking_requests (
    id TEXT PRIMARY KEY,
    tag TEXT NOT NULL DEFAULT 'Praktikum Pengganti',
    lab_name TEXT NOT NULL,
    title TEXT NOT NULL,
    date_label TEXT NOT NULL,
    time_range TEXT NOT NULL,
    requester_initials TEXT NOT NULL DEFAULT 'AS',
    requester_name TEXT NOT NULL,
    requester_role TEXT NOT NULL DEFAULT 'Asisten Lab',
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'menunggu' CHECK (status IN ('menunggu', 'disetujui', 'ditolak')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.praktikum_schedules (
    id, course_id, course_name, kelas, day_index, day_short, start_time, end_time, room, asisten, week_number
) VALUES
    ('sched-pemob', 'pemob', 'Pemrograman Mobile', 'TIF 3001 - Kelas C', 0, 'Sen', '08:00', '09:40', 'Lab Komputer 1', 'Andi Pratama', 4),
    ('sched-desain', 'desain', 'Desain Interaksi', 'TIF 3002 - Kelas C', 0, 'Sen', '13:00', '14:40', 'Lab Jaringan 2', 'Feri Gunawan', 4),
    ('sched-adj', 'adj', 'Analisis Desain Jaringan', 'TIF 3003 - Kelas C', 2, 'Rab', '10:00', '11:40', 'Lab Jaringan 1', 'Sinta Marpaung', 4),
    ('sched-ml', 'ml', 'Machine Learning', 'TIF 3004 - Kelas C', 3, 'Kam', '13:00', '14:40', 'Lab AI & Data', 'Rizky Harahap', 4)
ON CONFLICT (id) DO UPDATE SET
    course_name = EXCLUDED.course_name,
    kelas = EXCLUDED.kelas,
    day_index = EXCLUDED.day_index,
    day_short = EXCLUDED.day_short,
    start_time = EXCLUDED.start_time,
    end_time = EXCLUDED.end_time,
    room = EXCLUDED.room,
    asisten = EXCLUDED.asisten;

INSERT INTO public.announcements (
    course_id, category, tag, tag_red, title, body, author, old_schedule, new_schedule, room
) VALUES
(
    'ml', 1, 'Perubahan Jadwal', TRUE,
    'Pemindahan Jadwal Praktikum',
    'Pertemuan 4 Praktikum Machine Learning Kelas C dipindahkan ke hari Kamis karena penggunaan lab untuk ujian.',
    'Rizky Harahap • Asisten Lab',
    'Sel, 29 Sep • 13:00',
    'Kam, 01 Okt • 13:00',
    'Lab AI & Data'
),
(
    'pemob', 2, 'Umum', FALSE,
    'Batas Unggah Tugas 4',
    'Jangan lupa mengunggah laporan PDF dan tautan repositori Tugas 4 sebelum pukul 10:30 WIB besok.',
    'Andi Pratama • Asisten Lab',
    NULL, NULL, NULL
)
ON CONFLICT DO NOTHING;

INSERT INTO public.room_booking_requests (
    id, tag, lab_name, title, date_label, time_range,
    requester_initials, requester_name, requester_role, reason, status
) VALUES
(
    'room-req-1', 'Praktikum Pengganti', 'Lab Komputer 1',
    'Praktikum Basis Data • Kelas B', 'Kam, 01 Okt 2026', '13:00–14:40',
    'SM', 'Sinta Marpaung', 'Asisten Lab',
    'Pengganti pertemuan 3 yang bertepatan dengan libur nasional.', 'menunggu'
),
(
    'room-req-2', 'Kelas Pengganti', 'Lab Multimedia',
    'Pemrograman Mobile • Kelas A', 'Jum, 02 Okt 2026', '10:00–11:40',
    'AR', 'Abbil Rizki', 'Asisten Lab',
    'Kelas pengganti karena perbaikan proyektor di Lab Komputer 1.', 'menunggu'
)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- BAGIAN 6: SHIFT JAGA ASISTEN, TUKAR SHIFT & KODE AKSES HARIAN LABORAN
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.lab_shifts (
    id TEXT PRIMARY KEY,
    day_index INT NOT NULL CHECK (day_index BETWEEN 0 AND 5),
    day_label TEXT NOT NULL,
    shift_label TEXT NOT NULL DEFAULT 'Shift Pagi',
    course_name TEXT NOT NULL,
    time_range TEXT NOT NULL,
    room TEXT NOT NULL,
    asisten_name TEXT NOT NULL,
    asisten_initials TEXT NOT NULL DEFAULT 'AS',
    partner_name TEXT NOT NULL DEFAULT '',
    attendance_status TEXT NOT NULL DEFAULT 'belum' CHECK (attendance_status IN ('hadir', 'terlambat', 'belum')),
    check_in_time TEXT,
    discipline_pct INT NOT NULL DEFAULT 90 CHECK (discipline_pct BETWEEN 0 AND 100),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lab_shifts_day ON public.lab_shifts(day_index);

CREATE TABLE IF NOT EXISTS public.shift_swap_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    swap_code TEXT UNIQUE NOT NULL,
    requester_id TEXT,
    requester_name TEXT NOT NULL,
    requester_initials TEXT NOT NULL DEFAULT 'AS',
    target_name TEXT NOT NULL,
    target_initials TEXT NOT NULL DEFAULT 'AS',
    from_shift_id TEXT,
    from_shift_label TEXT NOT NULL,
    to_shift_id TEXT,
    to_shift_label TEXT NOT NULL,
    reason TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    is_incoming BOOLEAN NOT NULL DEFAULT false,
    is_mine BOOLEAN NOT NULL DEFAULT true,
    meta_note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    decided_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_shift_swaps_status ON public.shift_swap_requests(status);
CREATE INDEX IF NOT EXISTS idx_shift_swaps_created ON public.shift_swap_requests(created_at DESC);

CREATE TABLE IF NOT EXISTS public.assistant_access_codes (
    id TEXT PRIMARY KEY DEFAULT 'today',
    code TEXT NOT NULL,
    valid_until TEXT NOT NULL DEFAULT '17:00 WIB',
    generated_by TEXT NOT NULL DEFAULT 'Laboran',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.lab_shifts (
    id, day_index, day_label, shift_label, course_name, time_range, room,
    asisten_name, asisten_initials, partner_name, attendance_status, check_in_time, discipline_pct
) VALUES
    ('shift-sen-pagi', 0, 'Sen, 28 Sep', 'Shift Pagi', 'Praktikum Pemrograman Mobile', '08:00–09:40 WIB', 'Lab Komputer 1', 'Abbil Rizki', 'AR', 'Rizky Harahap', 'hadir', '07:52', 96),
    ('shift-sen-siang', 0, 'Sen, 28 Sep', 'Shift Siang', 'Praktikum Basis Data', '13:00–14:40 WIB', 'Lab Jaringan 2', 'Feri Gunawan', 'FG', 'Sinta Marpaung', 'hadir', '07:58', 92),
    ('shift-sel-pagi', 1, 'Sel, 29 Sep', 'Shift Pagi', 'Praktikum Desain Interaksi', '10:00–11:40 WIB', 'Lab Multimedia', 'Sinta Marpaung', 'SM', 'Feri Gunawan', 'terlambat', '08:12', 78),
    ('shift-rab-siang', 2, 'Rab, 30 Sep', 'Shift Siang', 'Praktikum Administrasi Jaringan', '13:00–14:40 WIB', 'Lab Jaringan 2', 'Feri Gunawan', 'FG', 'Abbil Rizki', 'hadir', '12:55', 92),
    ('shift-kam-pagi', 3, 'Kam, 01 Okt', 'Shift Pagi', 'Praktikum Machine Learning', '08:00–09:40 WIB', 'Lab Komputer 1', 'Abbil Rizki', 'AR', 'Rizky Harahap', 'belum', NULL, 96),
    ('shift-jum-pagi', 4, 'Jum, 02 Okt', 'Shift Pagi', 'Praktikum Jaringan Komputer', '10:00–11:40 WIB', 'Lab Jaringan 2', 'Rizky Harahap', 'RH', 'Sinta Marpaung', 'belum', NULL, 85)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.shift_swap_requests (
    swap_code, requester_name, requester_initials, target_name, target_initials,
    from_shift_id, from_shift_label, to_shift_id, to_shift_label,
    reason, status, is_incoming, is_mine, meta_note
) VALUES
    (
        '#TS-015', 'Feri Gunawan', 'FG', 'Abbil Rizki', 'AR',
        'shift-rab-siang', 'Rab, 30 Sep • 13:00',
        'shift-kam-pagi', 'Kam, 01 Okt • 08:00',
        'Ada jadwal bimbingan skripsi di hari Rabu siang.',
        'pending', true, true, 'Menunggu konfirmasi anda'
    ),
    (
        '#TS-014', 'Abbil Rizki', 'AR', 'Feri Gunawan', 'FG',
        'shift-rab-siang', 'Rab, 30 Sep • 13:00',
        'shift-kam-pagi', 'Kam, 01 Okt • 08:00',
        'Pertukaran shift rutin minggu ke-4.',
        'approved', false, true, 'Diajukan 27 Sep 2026 • Disetujui Feri'
    ),
    (
        '#TS-013', 'Sinta Marpaung', 'SM', 'Rizky Harahap', 'RH',
        'shift-sel-pagi', 'Sel, 22 Sep • 10:00',
        'shift-jum-pagi', 'Kam, 24 Sep • 13:00',
        'Mengikuti seminar nasional TI.',
        'approved', false, false, 'Diajukan 20 Sep 2026 • Disetujui Rizky'
    ),
    (
        '#TS-011', 'Abbil Rizki', 'AR', 'Sinta Marpaung', 'SM',
        'shift-sen-pagi', 'Jum, 18 Sep • 08:00',
        'shift-sen-siang', 'Sen, 21 Sep • 13:00',
        'Bentrok dengan kelas kuliah pengganti.',
        'rejected', false, true, 'Diajukan 16 Sep 2026 • Ditolak Sinta'
    )
ON CONFLICT (swap_code) DO NOTHING;

INSERT INTO public.assistant_access_codes (id, code, valid_until, generated_by)
VALUES ('today', 'ITLG-4821', '17:00 WIB', 'Reagan Brian')
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- BAGIAN 7: VALIDASI NILAI AKHIR DOSEN, SANGGAH NILAI & HUBUNGI ASISTEN
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.grade_validations (
    course_id TEXT PRIMARY KEY,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'revision_requested', 'validated')),
    revision_part TEXT,
    revision_note TEXT,
    validated_by TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.grade_appeals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL,
    modul INT NOT NULL,
    user_identifier TEXT NOT NULL,
    user_name TEXT NOT NULL,
    components_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    reason TEXT NOT NULL,
    attachment_name TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_grade_appeals_course ON public.grade_appeals(course_id, modul);

CREATE TABLE IF NOT EXISTS public.assistant_followups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_nim TEXT NOT NULL,
    student_name TEXT NOT NULL,
    assistant_name TEXT NOT NULL,
    followup_type TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.grade_validations (course_id, status) VALUES
    ('pemob', 'pending'),
    ('desain', 'pending'),
    ('adj', 'validated'),
    ('ml', 'validated')
ON CONFLICT (course_id) DO NOTHING;

-- =============================================================================
-- BAGIAN 8: NOTIFIKASI LINTAS ROLE (PRAKTIKAN ↔ ASLAB ↔ LABORAN ↔ DOSEN)
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_role TEXT NOT NULL CHECK (target_role IN ('praktikan', 'aslab', 'laboran', 'dosen')),
    icon TEXT NOT NULL DEFAULT 'info',
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    target_key TEXT NOT NULL DEFAULT '',
    important BOOLEAN NOT NULL DEFAULT FALSE,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_role_created
    ON public.notifications(target_role, created_at DESC);

INSERT INTO public.notifications (target_role, icon, title, body, target_key, important, is_read, created_at)
SELECT * FROM (VALUES
    ('praktikan', 'qrcode', 'Presensi Berlangsung', 'Praktikum Pemrograman Mobile • Lab Komputer 1 sedang dibuka oleh Andi Pratama', 'presensi', TRUE, FALSE, NOW() - INTERVAL '5 minutes'),
    ('praktikan', 'bullhorn_outline', 'Pemindahan Jadwal Praktikum', 'Machine Learning Kelas C pindah ke Kam, 01 Okt • 13:00 di Lab AI & Data', 'pengumuman', TRUE, FALSE, NOW() - INTERVAL '2 hours'),
    ('praktikan', 'clipboard', 'Batas Unggah Tugas 4', 'Kumpulkan laporan & tautan repositori Pemrograman Mobile sebelum 10:30 WIB', 'editTugas', FALSE, FALSE, NOW() - INTERVAL '4 hours'),
    ('praktikan', 'trophy', 'Nilai Modul 3 Tersedia', 'Nilai Layout & Navigasi (88) telah diterbitkan oleh asisten', 'detailNilai', FALSE, TRUE, NOW() - INTERVAL '1 day'),
    ('aslab', 'file', 'Pengajuan Izin Menunggu', 'Rina Novita mengajukan Izin Sakit untuk Pertemuan 5 Pemrograman Mobile', 'persetujuanIzin', TRUE, FALSE, NOW() - INTERVAL '10 minutes'),
    ('aslab', 'clipboard', 'Tugas 4 Perlu Dievaluasi', '20 praktikan telah mengumpulkan Tugas 4 Praktikum Pemrograman Mobile', 'evaluasi', TRUE, FALSE, NOW() - INTERVAL '1 hour'),
    ('aslab', 'arrow_right_left', 'Permintaan Tukar Shift', 'Feri Gunawan meminta bertukar shift jaga minggu ini', 'shiftJaga', FALSE, FALSE, NOW() - INTERVAL '3 hours'),
    ('aslab', 'question', 'Hasil Kuis Pre-Test Modul 4', '22 dari 24 praktikan telah menyelesaikan kuis dengan rata-rata 78,5', 'hasilKuis', FALSE, TRUE, NOW() - INTERVAL '1 day'),
    ('laboran', 'wrench_outline', 'Tiket Kerusakan Baru', 'PC-12 Lab Komputer 1 dilaporkan mengalami kendala monitor tidak tampil', 'tiket', TRUE, FALSE, NOW() - INTERVAL '15 minutes'),
    ('laboran', 'calendar', '2 Pengajuan Pemakaian Ruangan', 'Menunggu persetujuan jadwal pemakaian Lab Komputer 2 & Lab Jaringan 1', 'ruangan', TRUE, FALSE, NOW() - INTERVAL '2 hours'),
    ('laboran', 'key', 'Presensi Asisten On-Duty', 'Andi Pratama & Feri Gunawan telah verifikasi kehadiran di laboratorium', 'presensi', FALSE, TRUE, NOW() - INTERVAL '1 day'),
    ('dosen', 'triangle_alert', 'Peringatan Dini: 3 Praktikan', 'Kehadiran atau nilai di bawah batas minimal pada grup praktikum diampu', 'peringatan', TRUE, FALSE, NOW() - INTERVAL '5 minutes'),
    ('dosen', 'circle_check', 'Modul 4 Selesai Dinilai', 'Praktikum Pemrograman Mobile Kelas C • Andi Pratama', 'validasi', FALSE, FALSE, NOW() - INTERVAL '1 hour'),
    ('dosen', 'chart_bar', 'Rekap Kehadiran Minggu ke-4', 'Rata-rata kehadiran 91% dari 4 grup praktikum aktif', 'laporan', FALSE, FALSE, NOW() - INTERVAL '2 hours'),
    ('dosen', 'clipboard', 'Nilai Akhir Siap Divalidasi', 'Pemrograman Mobile Kelas C menunggu validasi dosen pengampu', 'validasi', TRUE, TRUE, NOW() - INTERVAL '1 day')
) AS seed(target_role, icon, title, body, target_key, important, is_read, created_at)
WHERE NOT EXISTS (SELECT 1 FROM public.notifications LIMIT 1);

-- =============================================================================
-- BAGIAN 9: SUPABASE STORAGE BUCKET (`itlg-uploads`) UNTUK UPLOAD BERKAS NYATA
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('itlg-uploads', 'itlg-uploads', TRUE, 20971520)
ON CONFLICT (id) DO UPDATE SET
    public = TRUE,
    file_size_limit = 20971520;

DROP POLICY IF EXISTS "itlg_uploads_select_all" ON storage.objects;
CREATE POLICY "itlg_uploads_select_all"
    ON storage.objects FOR SELECT USING (bucket_id = 'itlg-uploads');

DROP POLICY IF EXISTS "itlg_uploads_insert_all" ON storage.objects;
CREATE POLICY "itlg_uploads_insert_all"
    ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'itlg-uploads');

DROP POLICY IF EXISTS "itlg_uploads_update_all" ON storage.objects;
CREATE POLICY "itlg_uploads_update_all"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'itlg-uploads')
    WITH CHECK (bucket_id = 'itlg-uploads');

DROP POLICY IF EXISTS "itlg_uploads_delete_all" ON storage.objects;
CREATE POLICY "itlg_uploads_delete_all"
    ON storage.objects FOR DELETE USING (bucket_id = 'itlg-uploads');

-- =============================================================================
-- BAGIAN 10: ROW LEVEL SECURITY (RLS) & SUPABASE REALTIME PUBLICATION
-- =============================================================================

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY[
        'praktikum_courses',
        'praktikum_meetings',
        'tugas_submissions',
        'kuis_attempts',
        'asisten_ratings',
        'attendance_sessions',
        'attendance_records',
        'leave_requests',
        'lab_desks',
        'desk_bookings',
        'lab_tickets',
        'lab_software',
        'praktikum_schedules',
        'announcements',
        'room_booking_requests',
        'lab_shifts',
        'shift_swap_requests',
        'assistant_access_codes',
        'grade_validations',
        'grade_appeals',
        'assistant_followups',
        'notifications'
    ] LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_select_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_select_all" ON public.%I FOR SELECT USING (true)', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_insert_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_insert_all" ON public.%I FOR INSERT WITH CHECK (true)', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_update_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_update_all" ON public.%I FOR UPDATE USING (true) WITH CHECK (true)', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_delete_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_delete_all" ON public.%I FOR DELETE USING (true)', tbl, tbl);

        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        EXCEPTION WHEN duplicate_object THEN NULL;
        END;
    END LOOP;
END $$;
