-- Skema database utama PostgreSQL & Supabase - ITLG Mobile
--
-- Cara pakai (proyek Supabase baru): Dashboard → SQL Editor → tempel seluruh
-- isi berkas ini → Run. Aman dijalankan ulang (idempoten).
-- Sudah termasuk perbaikan hasil QA 24 Nov 2026 (lihat qa/BUGS.md):
--   * email akun wajib @students.usu.ac.id
--   * ruangan hanya master Lab Jaringan 1–4 (tanpa Lab Jaringan 1 / AI & Data / Multimedia)
--   * tidak ada meja demo "terisi" dan tidak ada sesi presensi aktif bawaan
--   * tabel soal kuis (quiz_questions), notifikasi pribadi (target_user),
--     status dibaca per pengguna (notification_reads)
--   * RLS: data hanya untuk pengguna yang sudah login; profil hanya bisa
--     diubah pemiliknya; unggah/hapus berkas hanya pengguna login
--   * BAGIAN 11 menyelaraskan database lama yang dibuat dari versi sebelumnya

-- BAGIAN 1: EKSTENSI, TIPE ENUM, PROFIL PENGGUNA, AUTH 4 ROLE & RESET PASSWORD

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
    ON public.profiles FOR UPDATE TO authenticated
    USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

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

-- Catatan keamanan: fungsi ini terbuka untuk anon karena dipakai "Lupa Password"
-- (OTP dibuat & dicek di aplikasi). Setelah Lupa Password dipindah ke pemulihan
-- bawaan Supabase Auth, cabut aksesnya:
--   REVOKE EXECUTE ON FUNCTION public.reset_password_by_email(text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reset_password_by_email(text, text) TO anon, authenticated, service_role;

-- Fungsi RPC Verifikasi Kata Sandi Saat Ini (untuk halaman Ubah Kata Sandi dari Profil)
CREATE OR REPLACE FUNCTION public.verify_user_password(user_email text, current_password text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_hash text;
BEGIN
  SELECT encrypted_password INTO v_hash
  FROM auth.users
  WHERE lower(email) = lower(user_email)
     OR id IN (SELECT id FROM public.profiles WHERE lower(email) = lower(user_email))
  LIMIT 1;

  IF v_hash IS NULL THEN
    RETURN false;
  END IF;

  RETURN crypt(current_password, v_hash) = v_hash;
END;
$$;

-- Hanya pengguna login (halaman Ubah Kata Sandi). Fungsi PostgreSQL otomatis
-- bisa dieksekusi PUBLIC, jadi cabut dari PUBLIC & anon.
REVOKE EXECUTE ON FUNCTION public.verify_user_password(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.verify_user_password(text, text) TO authenticated, service_role;

-- Seed 4 Akun Utama (Praktikan, Aslab, Laboran, Dosen) - Password: password123
-- Akun yang sudah ada TIDAK ditimpa kata sandi & namanya saat skrip dijalankan ulang.
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
        confirmation_token = '', recovery_token = '', email_change_token_new = '', email_change = '';

    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (uid_praktikan, '241402105', 'Andre Al Farizi Sebayang', 'andreal@students.usu.ac.id', 'praktikan', '081234567890')
    ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
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
        confirmation_token = '', recovery_token = '', email_change_token_new = '', email_change = '';

    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (uid_aslab, '211402001', 'Abbil Rizki', 'abbilrizki@students.usu.ac.id', 'aslab', '081298765432')
    ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
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
        confirmation_token = '', recovery_token = '', email_change_token_new = '', email_change = '';

    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (uid_laboran, '198501012010011001', 'Reagan Brian', 'reaganbrian@students.usu.ac.id', 'laboran', '081377889900')
    ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
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
        confirmation_token = '', recovery_token = '', email_change_token_new = '', email_change = '';

    INSERT INTO public.profiles (id, identifier, full_name, email, role, phone)
    VALUES (uid_dosen, '198705122015041002', 'Dr. Eng. Daniele Christian, M.Kom.', 'danielechristian@students.usu.ac.id', 'dosen', '081122334455')
    ON CONFLICT (id) DO UPDATE SET
        identifier = EXCLUDED.identifier,
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

-- Validasi akun: email wajib @students.usu.ac.id (revisi BE).
-- Dipasang hanya bila semua profil sudah sesuai; bila belum, muncul NOTICE.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'profiles_email_students_usu') THEN
        RETURN;
    END IF;
    IF EXISTS (SELECT 1 FROM public.profiles
               WHERE email !~* '^[A-Za-z0-9._%+-]+@students\.usu\.ac\.id$') THEN
        RAISE NOTICE 'Constraint email dilewati: masih ada profil yang bukan @students.usu.ac.id.';
    ELSE
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_email_students_usu
            CHECK (email ~* '^[A-Za-z0-9._%+-]+@students\.usu\.ac\.id$');
    END IF;
END $$;

-- BAGIAN 2: PRAKTIKUM (4 MATA KULIAH), PERTEMUAN, TUGAS, KUIS & RATING ASISTEN

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
    'pemob', 'TIF 3001 - Kom C (C1 & C2)', 'Pemrograman Mobile', 'Semester Ganjil 2026/2027',
    'Andi Pratama', 'AP', 'Lab Jaringan 1',
    'Sen • C1 08:00 | C2 10:00', 'Sen, C1 08:00–09:40 • C2 10:00–11:40', 'Sen, C1 08:00–09:40 | C2 10:00–11:40', 'C1 08:00–09:40 • C2 10:00–11:40 WIB',
    4, 12,
    'State Management',
    'Pembahasan State Management Flutter secara mendalam: setState, ChangeNotifier, dan Provider.',
    'Panduan State Management Flutter', 'Panduan_State_Management_Flutter.pdf',
    'Tugas 4 : Implementasi State Management', 'Batas 10:30 WIB, 29 Sep 2026',
    'Pre-Test Modul 4 : State Management', 'Post-Test Modul 4 : State Management', 1
),
(
    'desain', 'TIF 3002 - Kom C (C1 & C2)', 'Desain Interaksi', 'Semester Ganjil 2026/2027',
    'Feri Gunawan', 'FG', 'Lab Jaringan 2',
    'Sel • C1 08:00 | C2 10:00', 'Sel, C1 08:00–09:40 • C2 10:00–11:40', 'Sel, C1 08:00–09:40 | C2 10:00–11:40', 'C1 08:00–09:40 • C2 10:00–11:40 WIB',
    4, 12,
    'Figma Management',
    'Pembahasan pengelolaan file Figma secara mendalam: komponen, variant, dan auto layout.',
    'Panduan Penggunaan Figma', 'Panduan_Penggunaan_Figma.pdf',
    'Tugas 4 : Pembuatan Prototype Figma', 'Batas 10:30 WIB, 30 Sep 2026',
    'Pre-Test Modul 4 : Figma Management', 'Post-Test Modul 4 : Figma Management', 2
),
(
    'adj', 'TIF 3003 - Kom C (C1 & C2)', 'Analisis Desain Jaringan', 'Semester Ganjil 2026/2027',
    'Sinta Marpaung', 'SM', 'Lab Jaringan 1',
    'Rab • C1 10:00 | C2 13:00', 'Rab, C1 10:00–11:40 • C2 13:00–14:40', 'Rab, C1 10:00–11:40 | C2 13:00–14:40', 'C1 10:00–11:40 • C2 13:00–14:40 WIB',
    4, 12,
    'VLAN & Inter-VLAN Routing',
    'Perancangan segmentasi VLAN, trunking 802.1Q, dan konfigurasi Router-on-a-Stick pada Cisco Packet Tracer.',
    'Panduan Konfigurasi VLAN & Trunking', 'Panduan_VLAN_InterVLAN_Routing.pdf',
    'Tugas 4 : Topologi Multi-VLAN Kampus', 'Batas 10:30 WIB, 01 Okt 2026',
    'Pre-Test Modul 4 : VLAN & Routing', 'Post-Test Modul 4 : VLAN & Routing', 3
),
(
    'ml', 'TIF 3004 - Kom C (C1 & C2)', 'Machine Learning', 'Semester Ganjil 2026/2027',
    'Rizky Harahap', 'RH', 'Lab Jaringan 3',
    'Kam • C1 13:00 | C2 15:00', 'Kam, C1 13:00–14:40 • C2 15:00–16:40', 'Kam, C1 13:00–14:40 | C2 15:00–16:40', 'C1 13:00–14:40 • C2 15:00–16:40 WIB',
    4, 12,
    'Klasifikasi Supervised Learning',
    'Implementasi algoritma Decision Tree, Random Forest, dan evaluasi confusion matrix menggunakan scikit-learn.',
    'Panduan Klasifikasi Supervised ML', 'Panduan_Klasifikasi_ScikitLearn.pdf',
    'Tugas 4 : Model Klasifikasi Dataset Medis', 'Batas 10:30 WIB, 02 Okt 2026',
    'Pre-Test Modul 4 : Klasifikasi ML', 'Post-Test Modul 4 : Klasifikasi ML', 4
)
ON CONFLICT (id) DO UPDATE SET
    code = EXCLUDED.code,
    jadwal_daftar = EXCLUDED.jadwal_daftar,
    jadwal_detail = EXCLUDED.jadwal_detail,
    jadwal_absensi = EXCLUDED.jadwal_absensi,
    jam = EXCLUDED.jam;

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

('desain-m5', 'desain', 5, 'Modul 5 • Design System', 'Sel, 06 Okt 2026 • 08:00–09:40 WIB', 'Membangun token warna, tipografi, dan pustaka komponen terstandar.', 'Panduan Design System', 'Modul_5_Design_System.pdf', 'Tugas 5 : Design System Mini', 'Batas 10:30 WIB, 13 Okt 2026', 'Pre-Test Modul 5 : Design System', 'upcoming', NULL, NULL, NULL),
('desain-m4', 'desain', 4, 'Modul 4 • Figma Management', 'Sel, 29 Sep 2026 • 08:00–09:40 WIB', 'Pembahasan materi Figma secara mendalam: komponen, variant, dan auto layout.', 'Panduan Penggunaan Figma', 'Panduan_Penggunaan_Figma.pdf', 'Tugas 4 : Pembuatan Prototype Figma', 'Batas 10:30 WIB, 30 Sep 2026', 'Pre-Test Modul 4 : Figma Management', 'hadir', 'qrcode', 'Tercatat 08:02 WIB melalui pindai QR', NULL),
('desain-m3', 'desain', 3, 'Modul 3 • Prototyping Dasar', 'Sel, 22 Sep 2026 • 08:00–09:40 WIB', 'Membuat alur interaksi interaktif dan transisi smart animate.', 'Materi Prototyping Dasar', 'Modul_3_Prototyping.pdf', 'Tugas 3 : Alur Login Interaktif', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 08:00 WIB melalui tombol hadir & lokasi', NULL),
('desain-m2', 'desain', 2, 'Modul 2 • Wireframing', 'Sel, 15 Sep 2026 • 08:00–09:40 WIB', 'Perancangan wireframe low-fidelity dan hierarki informasi.', 'Materi Wireframing', 'Modul_2_Wireframing.pdf', 'Tugas 2 : Wireframe Aplikasi Kampus', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'hadir', 'qrcode', 'Tercatat 07:58 WIB melalui pindai QR', NULL),
('desain-m1', 'desain', 1, 'Modul 1 • Pengenalan Figma', 'Sel, 08 Sep 2026 • 08:00–09:40 WIB', 'Pengenalan workspace Figma, frame, grid, dan constraints.', 'Materi Pengenalan Figma', 'Modul_1_Figma.pdf', 'Tugas 1 : Eksplorasi Frame Figma', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 08:01 WIB melalui pindai QR', NULL),

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

-- Soal kuis buatan Aslab (per praktikum, urutan = position).
-- Catatan: answer_index masih terbaca praktikan yang login; untuk menyembunyikan
-- kunci jawaban perlu view/RPC penilaian di server.
CREATE TABLE IF NOT EXISTS public.quiz_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL,
    meeting_number INT NOT NULL DEFAULT 0,
    position INT NOT NULL,
    question TEXT NOT NULL,
    options JSONB NOT NULL,
    answer_index INT NOT NULL CHECK (answer_index >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (course_id, position)
);

-- BAGIAN 3: PRESENSI (SESI AKTIF, QR DINAMIS 5 MENIT, REKAMAN GPS & IZIN)

CREATE TABLE IF NOT EXISTS public.attendance_sessions (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL DEFAULT 'pemob',
    meeting_number INT NOT NULL DEFAULT 5,
    lab_name TEXT NOT NULL DEFAULT 'Lab Jaringan 1',
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
    desk_number INT,
    status INT NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2)),
    decided_by TEXT,
    decision_history_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.leave_requests ADD COLUMN IF NOT EXISTS desk_number INT;
ALTER TABLE public.leave_requests ADD COLUMN IF NOT EXISTS decision_history_json JSONB NOT NULL DEFAULT '[]'::jsonb;

CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON public.leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_user ON public.leave_requests(user_identifier);

-- Riwayat sesi contoh (SUDAH DITUTUP). Sesi aktif hanya dibuat Aslab dari aplikasi.
INSERT INTO public.attendance_sessions (
    id, course_id, meeting_number, lab_name, lat, lng, radius_m,
    allow_qr, allow_button, require_signature, duration_minutes, status, started_by,
    started_at, ended_at
) VALUES (
    'pemob-p5', 'pemob', 5, 'Lab Jaringan 1', 3.5621, 98.6600, 50.0,
    TRUE, TRUE, TRUE, 15, 'closed', 'Andi Pratama',
    NOW() - INTERVAL '2 hours', NOW() - INTERVAL '100 minutes'
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

-- Seed idempoten (lihat catatan seed pengumuman).
INSERT INTO public.leave_requests (
    course_id, meeting_number, user_identifier, user_name,
    leave_type, pertemuan_label, note, file_name, status
)
SELECT v.* FROM (VALUES
(
    'pemob', 5, '231402045', 'Rina Novita',
    'Izin Sakit', '5 • Sen, 05 Okt',
    'Demam dan disarankan beristirahat oleh dokter klinik kampus.',
    'surat_dokter.pdf', 0
),
(
    'pemob', 4, '231402051', 'Dimas Saputra',
    'Kendala Perangkat', '4 • Sen, 28 Sep',
    'Kamera ponsel rusak sehingga tidak dapat memindai QR. Saya hadir di Lab Jaringan 1.',
    NULL, 0
)) AS v(course_id, meeting_number, user_identifier, user_name,
    leave_type, pertemuan_label, note, file_name, status)
WHERE NOT EXISTS (
    SELECT 1 FROM public.leave_requests l
    WHERE l.course_id = v.course_id
      AND l.meeting_number = v.meeting_number
      AND l.user_identifier = v.user_identifier
      AND l.note = v.note
);

-- BAGIAN 4: MASTER LAB (JARINGAN 1-4), MEJA 6x5, TIKET LK- & INVENTARIS SOFTWARE

CREATE TABLE IF NOT EXISTS public.labs (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    building_floor TEXT NOT NULL,
    capacity INT NOT NULL DEFAULT 30,
    lat DOUBLE PRECISION NOT NULL DEFAULT 3.5621,
    lng DOUBLE PRECISION NOT NULL DEFAULT 98.6600,
    radius_m DOUBLE PRECISION NOT NULL DEFAULT 50.0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.labs (id, name, building_floor, capacity, lat, lng, radius_m) VALUES
    ('lab-jaringan-1', 'Lab Jaringan 1', 'Gedung C • Lantai 2', 30, 3.5621, 98.6600, 50.0),
    ('lab-jaringan-2', 'Lab Jaringan 2', 'Gedung C • Lantai 2', 30, 3.5621, 98.6601, 50.0),
    ('lab-jaringan-3', 'Lab Jaringan 3', 'Gedung D • Lantai 2', 30, 3.5622, 98.6602, 50.0),
    ('lab-jaringan-4', 'Lab Jaringan 4', 'Gedung D • Lantai 3', 30, 3.5622, 98.6603, 50.0)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    building_floor = EXCLUDED.building_floor,
    capacity = EXCLUDED.capacity;

CREATE TABLE IF NOT EXISTS public.lab_desks (
    id BIGSERIAL PRIMARY KEY,
    lab_name TEXT NOT NULL,
    desk_number INT NOT NULL,
    pc_code TEXT NOT NULL,
    row_num INT NOT NULL DEFAULT 1,
    col_num INT NOT NULL DEFAULT 1,
    spec TEXT NOT NULL DEFAULT 'Core i5-12400 • 16 GB • SSD 512 GB',
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'taken', 'broken')),
    booked_by_user_id TEXT,
    booked_by_name TEXT,
    booked_at TIMESTAMPTZ,
    session_key TEXT NOT NULL DEFAULT 'PEMOB-PERTEMUAN-5',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (lab_name, desk_number)
);

ALTER TABLE public.lab_desks ADD COLUMN IF NOT EXISTS row_num INT NOT NULL DEFAULT 1;
ALTER TABLE public.lab_desks ADD COLUMN IF NOT EXISTS col_num INT NOT NULL DEFAULT 1;

-- RPC Transaksi Atomik Pilih / Pindah Meja (row lock FOR UPDATE + lepas meja lama dalam 1 transaksi)
CREATE OR REPLACE FUNCTION public.claim_or_move_desk(
    p_lab_name TEXT,
    p_desk_number INT,
    p_user_id TEXT,
    p_user_name TEXT,
    p_session_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_target public.lab_desks%ROWTYPE;
BEGIN
    SELECT * INTO v_target
    FROM public.lab_desks
    WHERE lab_name = p_lab_name AND desk_number = p_desk_number
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Meja tidak ditemukan');
    END IF;

    IF v_target.status = 'broken' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Meja sedang rusak');
    END IF;

    IF v_target.status = 'taken' AND v_target.booked_by_user_id IS DISTINCT FROM p_user_id THEN
        RETURN jsonb_build_object('success', false, 'error', 'Meja sudah ditempati praktikan lain');
    END IF;

    -- Lepaskan meja lama milik praktikan di lab yang sama dalam transaksi ini
    UPDATE public.lab_desks
    SET status = 'available',
        booked_by_user_id = NULL,
        booked_by_name = NULL,
        booked_at = NULL,
        updated_at = NOW()
    WHERE lab_name = p_lab_name
      AND booked_by_user_id = p_user_id
      AND desk_number <> p_desk_number
      AND status = 'taken';

    UPDATE public.desk_bookings
    SET status = 'released'
    WHERE lab_name = p_lab_name
      AND session_key = p_session_key
      AND user_identifier = p_user_id
      AND status = 'active';

    -- Tandai meja baru ditempati praktikan ini
    UPDATE public.lab_desks
    SET status = 'taken',
        booked_by_user_id = p_user_id,
        booked_by_name = p_user_name,
        booked_at = NOW(),
        session_key = p_session_key,
        updated_at = NOW()
    WHERE id = v_target.id;

    INSERT INTO public.desk_bookings (
        lab_name, desk_number, session_key, user_id, user_identifier, user_name, status, booked_at
    ) VALUES (
        p_lab_name, p_desk_number, p_session_key, p_user_id, p_user_id, p_user_name, 'active', NOW()
    );

    RETURN jsonb_build_object('success', true, 'desk_number', p_desk_number);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.claim_or_move_desk(TEXT, INT, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.claim_or_move_desk(TEXT, INT, TEXT, TEXT, TEXT) TO authenticated, service_role;

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
    photo_url TEXT,
    status INT NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2)),
    handling_note TEXT NOT NULL DEFAULT '',
    status_history_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.lab_tickets ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.lab_tickets ADD COLUMN IF NOT EXISTS status_history_json JSONB NOT NULL DEFAULT '[]'::jsonb;

CREATE INDEX IF NOT EXISTS idx_lab_tickets_lab_desk ON public.lab_tickets(lab_name, desk_number);
CREATE INDEX IF NOT EXISTS idx_lab_tickets_status ON public.lab_tickets(status);

CREATE TABLE IF NOT EXISTS public.lab_software (
    id BIGSERIAL PRIMARY KEY,
    lab_name TEXT NOT NULL,
    software_name TEXT NOT NULL,
    version TEXT NOT NULL DEFAULT '',
    target_scope TEXT NOT NULL DEFAULT 'Semua PC',
    icon TEXT NOT NULL DEFAULT 'code_tags',
    is_installed BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (lab_name, software_name)
);

ALTER TABLE public.lab_software ADD COLUMN IF NOT EXISTS version TEXT NOT NULL DEFAULT '';
ALTER TABLE public.lab_software ADD COLUMN IF NOT EXISTS target_scope TEXT NOT NULL DEFAULT 'Semua PC';

CREATE INDEX IF NOT EXISTS idx_lab_software_lab ON public.lab_software(lab_name);

-- 30 meja per lab (6 baris x 5 kolom). Semua tersedia kecuali 1 meja rusak per lab;
-- meja baru "terisi" hanya bila praktikan memilihnya saat sesi presensi aktif.
INSERT INTO public.lab_desks (lab_name, desk_number, pc_code, row_num, col_num, spec, status)
SELECT
    lab_title,
    n,
    'PC-' || LPAD(n::text, 2, '0'),
    ((n - 1) / 5) + 1,
    ((n - 1) % 5) + 1,
    CASE
        WHEN lab_title IN ('Lab Jaringan 3', 'Lab Jaringan 4') THEN 'Core i7-12700 • 16 GB • SSD 512 GB'
        ELSE 'Core i5-12400 • 16 GB • SSD 512 GB'
    END,
    CASE
        WHEN (lab_title = 'Lab Jaringan 1' AND n = 23)
          OR (lab_title = 'Lab Jaringan 2' AND n = 12)
          OR (lab_title = 'Lab Jaringan 3' AND n = 7)
          OR (lab_title = 'Lab Jaringan 4' AND n = 19)
        THEN 'broken'
        ELSE 'available'
    END
FROM (VALUES ('Lab Jaringan 1'), ('Lab Jaringan 2'), ('Lab Jaringan 3'), ('Lab Jaringan 4')) AS labs(lab_title)
CROSS JOIN generate_series(1, 30) AS n
ON CONFLICT (lab_name, desk_number) DO NOTHING;

-- Pastikan seluruh baris meja memiliki posisi 6 baris x 5 kolom (3 kiri | 2 kanan)
UPDATE public.lab_desks
SET row_num = ((desk_number - 1) / 5) + 1,
    col_num = ((desk_number - 1) % 5) + 1
WHERE desk_number BETWEEN 1 AND 30;

INSERT INTO public.lab_tickets (
    ticket_code, lab_name, desk_number, pc_code, icon, category,
    title, description, reporter_name, reporter_role, photo_name, status, handling_note
) VALUES
(
    '#TK-0921', 'Lab Jaringan 1', 12, 'PC-12', 'desktop_device', 'PC • Meja 12',
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
    '#TK-0918', 'Lab Jaringan 3', NULL, NULL, 'wifi', 'Jaringan',
    'Koneksi jaringan putus',
    'Tiga PC di baris belakang tidak mendapat alamat IP.',
    'Sinta Marpaung', 'aslab', 'foto_jaringan.jpg', 0, ''
)
ON CONFLICT (ticket_code) DO NOTHING;

INSERT INTO public.lab_software (lab_name, software_name, icon, is_installed) VALUES
    ('Lab Jaringan 1', 'MySQL 8.0', 'database_outline', true),
    ('Lab Jaringan 1', 'PostgreSQL 16', 'database_outline', true),
    ('Lab Jaringan 1', 'Android Studio', 'code_tags', false),
    ('Lab Jaringan 1', 'Visual Studio Code', 'code_tags', true),
    ('Lab Jaringan 1', 'Figma Desktop', 'pencil', true),
    ('Lab Jaringan 2', 'Cisco Packet Tracer', 'wifi', true),
    ('Lab Jaringan 2', 'Wireshark', 'wifi', true),
    ('Lab Jaringan 2', 'PuTTY / OpenSSH', 'code_tags', true),
    ('Lab Jaringan 2', 'VirtualBox', 'desktop_device', true),
    ('Lab Jaringan 2', 'GNS3', 'wifi', false),
    ('Lab Jaringan 3', 'Figma Desktop', 'pencil', true),
    ('Lab Jaringan 3', 'Blender 4.2', 'desktop_device', true),
    ('Lab Jaringan 3', 'Visual Studio Code', 'code_tags', true),
    ('Lab Jaringan 3', 'Unity Hub', 'code_tags', false),
    ('Lab Jaringan 3', 'OBS Studio', 'camera', true),
    ('Lab Jaringan 4', 'Python 3.12 & Anaconda', 'code_tags', true),
    ('Lab Jaringan 4', 'JupyterLab', 'code_tags', true),
    ('Lab Jaringan 4', 'Docker Desktop', 'database_outline', true),
    ('Lab Jaringan 4', 'Visual Studio Code', 'code_tags', true),
    ('Lab Jaringan 4', 'CUDA Toolkit 12', 'desktop_device', false)
ON CONFLICT (lab_name, software_name) DO NOTHING;

-- BAGIAN 5: JADWAL PRAKTIKUM, PENGUMUMAN & APPROVAL PEMINJAMAN RUANGAN

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
    rejection_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.room_booking_requests ADD COLUMN IF NOT EXISTS rejection_note TEXT;

INSERT INTO public.praktikum_schedules (
    id, course_id, course_name, kelas, day_index, day_short, start_time, end_time, room, asisten, week_number
) VALUES
    -- 1. Pemrograman Mobile — Kom C (Senin, 1 jam 40 menit per sesi)
    ('sched-pemob', 'pemob', 'Pemrograman Mobile', 'TIF 3001 - Kom C (Sesi C1)', 0, 'Sen', '08:00', '09:40', 'Lab Jaringan 1', 'Andi Pratama', 4),
    ('sched-pemob-c2', 'pemob', 'Pemrograman Mobile', 'TIF 3001 - Kom C (Sesi C2)', 0, 'Sen', '10:00', '11:40', 'Lab Jaringan 1', 'Andi Pratama', 4),
    -- 2. Desain Interaksi — Kom C (Selasa, 1 jam 40 menit per sesi)
    ('sched-desain', 'desain', 'Desain Interaksi', 'TIF 3002 - Kom C (Sesi C1)', 1, 'Sel', '08:00', '09:40', 'Lab Jaringan 2', 'Feri Gunawan', 4),
    ('sched-desain-c2', 'desain', 'Desain Interaksi', 'TIF 3002 - Kom C (Sesi C2)', 1, 'Sel', '10:00', '11:40', 'Lab Jaringan 2', 'Feri Gunawan', 4),
    -- 3. Analisis Desain Jaringan — Kom C (Rabu, 1 jam 40 menit per sesi)
    ('sched-adj', 'adj', 'Analisis Desain Jaringan', 'TIF 3003 - Kom C (Sesi C1)', 2, 'Rab', '10:00', '11:40', 'Lab Jaringan 1', 'Sinta Marpaung', 4),
    ('sched-adj-c2', 'adj', 'Analisis Desain Jaringan', 'TIF 3003 - Kom C (Sesi C2)', 2, 'Rab', '13:00', '14:40', 'Lab Jaringan 1', 'Sinta Marpaung', 4),
    -- 4. Machine Learning — Kom C (Kamis, 1 jam 40 menit per sesi)
    ('sched-ml', 'ml', 'Machine Learning', 'TIF 3004 - Kom C (Sesi C1)', 3, 'Kam', '13:00', '14:40', 'Lab Jaringan 3', 'Rizky Harahap', 4),
    ('sched-ml-c2', 'ml', 'Machine Learning', 'TIF 3004 - Kom C (Sesi C2)', 3, 'Kam', '15:00', '16:40', 'Lab Jaringan 3', 'Rizky Harahap', 4)
ON CONFLICT (id) DO UPDATE SET
    course_name = EXCLUDED.course_name,
    kelas = EXCLUDED.kelas,
    day_index = EXCLUDED.day_index,
    day_short = EXCLUDED.day_short,
    start_time = EXCLUDED.start_time,
    end_time = EXCLUDED.end_time,
    room = EXCLUDED.room,
    asisten = EXCLUDED.asisten;

-- Seed idempoten: PK UUID acak membuat ON CONFLICT tidak pernah terpicu,
-- jadi cek baris yang sama (judul + isi) sebelum menyisipkan.
INSERT INTO public.announcements (
    course_id, category, tag, tag_red, title, body, author, old_schedule, new_schedule, room
)
SELECT v.* FROM (VALUES
(
    'ml', 1, 'Perubahan Jadwal', TRUE,
    'Pemindahan Jadwal Praktikum',
    'Pertemuan 4 Praktikum Machine Learning Kelas C dipindahkan ke hari Kamis karena penggunaan lab untuk ujian.',
    'Rizky Harahap • Asisten Lab',
    'Sel, 29 Sep • 13:00',
    'Kam, 01 Okt • 13:00',
    'Lab Jaringan 3'
),
(
    'pemob', 2, 'Umum', FALSE,
    'Batas Unggah Tugas 4',
    'Jangan lupa mengunggah laporan PDF dan tautan repositori Tugas 4 sebelum pukul 10:30 WIB besok.',
    'Andi Pratama • Asisten Lab',
    NULL, NULL, NULL
)) AS v(course_id, category, tag, tag_red, title, body, author, old_schedule, new_schedule, room)
WHERE NOT EXISTS (
    SELECT 1 FROM public.announcements a
    WHERE a.title = v.title AND a.body = v.body
);

INSERT INTO public.room_booking_requests (
    id, tag, lab_name, title, date_label, time_range,
    requester_initials, requester_name, requester_role, reason, status
) VALUES
(
    'room-req-1', 'Praktikum Pengganti', 'Lab Jaringan 1',
    'Praktikum Basis Data • Kelas B', 'Kam, 01 Okt 2026', '13:00–14:40',
    'SM', 'Sinta Marpaung', 'Asisten Lab',
    'Pengganti pertemuan 3 yang bertepatan dengan libur nasional.', 'menunggu'
),
(
    'room-req-2', 'Kelas Pengganti', 'Lab Jaringan 2',
    'Pemrograman Mobile • Kelas A', 'Jum, 02 Okt 2026', '10:00–11:40',
    'AR', 'Abbil Rizki', 'Asisten Lab',
    'Kelas pengganti karena perbaikan proyektor di Lab Jaringan 1.', 'menunggu'
)
ON CONFLICT (id) DO NOTHING;

-- BAGIAN 6: SHIFT JAGA ASISTEN, TUKAR SHIFT & KODE AKSES HARIAN LABORAN

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
    ('shift-sen-pagi', 0, 'Sen, 28 Sep', 'Sesi C1', 'Praktikum Pemrograman Mobile (Kom C)', '08:00–09:40 WIB', 'Lab Jaringan 1', 'Abbil Rizki', 'AR', 'Andi Pratama', 'hadir', '07:52', 96),
    ('shift-sen-siang', 0, 'Sen, 28 Sep', 'Sesi C2', 'Praktikum Pemrograman Mobile (Kom C)', '10:00–11:40 WIB', 'Lab Jaringan 1', 'Andi Pratama', 'AP', 'Abbil Rizki', 'hadir', '09:55', 94),
    ('shift-sel-pagi', 1, 'Sel, 29 Sep', 'Sesi C1', 'Praktikum Desain Interaksi (Kom C)', '08:00–09:40 WIB', 'Lab Jaringan 2', 'Feri Gunawan', 'FG', 'Sinta Marpaung', 'terlambat', '08:12', 86),
    ('shift-rab-siang', 2, 'Rab, 30 Sep', 'Sesi C1', 'Praktikum Analisis Desain Jaringan (Kom C)', '10:00–11:40 WIB', 'Lab Jaringan 1', 'Sinta Marpaung', 'SM', 'Abbil Rizki', 'hadir', '09:55', 92),
    ('shift-kam-pagi', 3, 'Kam, 01 Okt', 'Sesi C1', 'Praktikum Machine Learning (Kom C)', '13:00–14:40 WIB', 'Lab Jaringan 3', 'Abbil Rizki', 'AR', 'Rizky Harahap', 'belum', NULL, 96),
    ('shift-jum-pagi', 3, 'Kam, 01 Okt', 'Sesi C2', 'Praktikum Machine Learning (Kom C)', '15:00–16:40 WIB', 'Lab Jaringan 3', 'Rizky Harahap', 'RH', 'Abbil Rizki', 'belum', NULL, 90)
ON CONFLICT (id) DO UPDATE SET
    day_index = EXCLUDED.day_index,
    day_label = EXCLUDED.day_label,
    shift_label = EXCLUDED.shift_label,
    course_name = EXCLUDED.course_name,
    time_range = EXCLUDED.time_range,
    room = EXCLUDED.room;

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

-- BAGIAN 7: VALIDASI NILAI AKHIR DOSEN, SANGGAH NILAI & HUBUNGI ASISTEN

CREATE TABLE IF NOT EXISTS public.grade_validations (
    course_id TEXT PRIMARY KEY,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('draft', 'pending', 'revision_requested', 'validated')),
    revision_part TEXT,
    revision_note TEXT,
    validated_by TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.grade_validations DROP CONSTRAINT IF EXISTS grade_validations_status_check;
ALTER TABLE public.grade_validations ADD CONSTRAINT grade_validations_status_check
    CHECK (status IN ('draft', 'pending', 'revision_requested', 'validated'));

CREATE TABLE IF NOT EXISTS public.grade_appeals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL,
    modul INT NOT NULL,
    user_identifier TEXT NOT NULL,
    user_name TEXT NOT NULL,
    components_json JSONB NOT NULL DEFAULT '[]'::jsonb,
    reason TEXT NOT NULL,
    attachment_name TEXT,
    current_score INT NOT NULL DEFAULT 70,
    proposed_score INT NOT NULL DEFAULT 85,
    assistant_recommendation TEXT,
    rejection_reason TEXT,
    decided_by TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'recommended_approve', 'recommended_reject', 'approved', 'rejected', 'reviewed', 'resolved')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.grade_appeals ADD COLUMN IF NOT EXISTS current_score INT NOT NULL DEFAULT 70;
ALTER TABLE public.grade_appeals ADD COLUMN IF NOT EXISTS proposed_score INT NOT NULL DEFAULT 85;
ALTER TABLE public.grade_appeals ADD COLUMN IF NOT EXISTS assistant_recommendation TEXT;
ALTER TABLE public.grade_appeals ADD COLUMN IF NOT EXISTS rejection_reason TEXT;
ALTER TABLE public.grade_appeals ADD COLUMN IF NOT EXISTS decided_by TEXT;
ALTER TABLE public.grade_appeals ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE public.grade_appeals DROP CONSTRAINT IF EXISTS grade_appeals_status_check;
ALTER TABLE public.grade_appeals ADD CONSTRAINT grade_appeals_status_check
    CHECK (status IN ('pending', 'recommended_approve', 'recommended_reject', 'approved', 'rejected', 'reviewed', 'resolved'));

CREATE TABLE IF NOT EXISTS public.grade_change_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT NOT NULL,
    modul INT NOT NULL,
    user_identifier TEXT NOT NULL,
    user_name TEXT NOT NULL,
    old_score INT NOT NULL,
    new_score INT NOT NULL,
    changed_by TEXT NOT NULL,
    reason TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_grade_change_logs_course ON public.grade_change_logs(course_id, modul);

CREATE INDEX IF NOT EXISTS idx_grade_appeals_course ON public.grade_appeals(course_id, modul);

CREATE TABLE IF NOT EXISTS public.assistant_followups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_nim TEXT NOT NULL,
    student_name TEXT NOT NULL,
    assistant_name TEXT NOT NULL,
    followup_type TEXT NOT NULL,
    message TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'done')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.assistant_followups ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending';
ALTER TABLE public.assistant_followups DROP CONSTRAINT IF EXISTS assistant_followups_status_check;
ALTER TABLE public.assistant_followups ADD CONSTRAINT assistant_followups_status_check
    CHECK (status IN ('pending', 'done'));

CREATE TABLE IF NOT EXISTS public.report_downloads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    course_name TEXT NOT NULL DEFAULT 'Semua Praktikum',
    file_name TEXT NOT NULL,
    format TEXT NOT NULL DEFAULT 'PDF',
    size_label TEXT NOT NULL DEFAULT '120 KB',
    local_path TEXT NOT NULL DEFAULT '',
    downloaded_by TEXT NOT NULL DEFAULT 'Dr. Eng. Daniele Christian, M.Kom.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_report_downloads_created ON public.report_downloads(created_at DESC);

INSERT INTO public.grade_validations (course_id, status) VALUES
    ('pemob', 'pending'),
    ('desain', 'pending'),
    ('adj', 'validated'),
    ('ml', 'validated')
ON CONFLICT (course_id) DO NOTHING;

INSERT INTO public.grade_appeals (
    course_id, modul, user_identifier, user_name, components_json, reason,
    attachment_name, current_score, proposed_score, status
)
SELECT * FROM (VALUES
    (
        'pemob', 4, '241402105', 'Andre Al Farizi Sebayang',
        '["Tugas Praktikum"]'::jsonb,
        'Repository GitHub untuk Tugas 4 sudah diperbarui sebelum batas waktu dan fitur state management berjalan lengkap.',
        'bukti_commit_tugas4.png', 74, 86, 'pending'
    )
) AS seed(course_id, modul, user_identifier, user_name, components_json, reason, attachment_name, current_score, proposed_score, status)
WHERE NOT EXISTS (SELECT 1 FROM public.grade_appeals LIMIT 1);

INSERT INTO public.assistant_followups (
    student_nim, student_name, assistant_name, followup_type, message, status
)
SELECT * FROM (VALUES
    (
        '231402070', 'Yoga Siregar', 'Abbil Rizki', 'Pendampingan & Evaluasi',
        'Mohon lakukan pendampingan khusus dan jadwalkan pengumpulan susulan Modul 4 sebelum validasi nilai akhir.',
        'pending'
    )
) AS seed(student_nim, student_name, assistant_name, followup_type, message, status)
WHERE NOT EXISTS (SELECT 1 FROM public.assistant_followups LIMIT 1);

INSERT INTO public.report_downloads (
    title, course_name, file_name, format, size_label, local_path, downloaded_by
)
SELECT * FROM (VALUES
    (
        'Rekap Kehadiran & Nilai Pemrograman Mobile',
        'Pemrograman Mobile',
        'Rekap_Nilai_Pemrograman_Mobile.pdf',
        'PDF',
        '142 KB',
        'Download/ITLG/Rekap_Nilai_Pemrograman_Mobile.pdf',
        'Dr. Eng. Daniele Christian, M.Kom.'
    ),
    (
        'Rekap Kehadiran Mingguan Kom C',
        'Semua Praktikum',
        'Rekap_Kehadiran_KomC.csv',
        'CSV',
        '38 KB',
        'Download/ITLG/Rekap_Kehadiran_KomC.csv',
        'Dr. Eng. Daniele Christian, M.Kom.'
    )
) AS seed(title, course_name, file_name, format, size_label, local_path, downloaded_by)
WHERE NOT EXISTS (SELECT 1 FROM public.report_downloads LIMIT 1);

-- BAGIAN 8: NOTIFIKASI LINTAS ROLE (PRAKTIKAN ↔ ASLAB ↔ LABORAN ↔ DOSEN)

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_role TEXT NOT NULL CHECK (target_role IN ('praktikan', 'aslab', 'laboran', 'dosen')),
    icon TEXT NOT NULL DEFAULT 'info',
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    target_key TEXT NOT NULL DEFAULT '',
    course_id TEXT,
    meeting_number INT,
    course_name TEXT,
    module_label TEXT,
    important BOOLEAN NOT NULL DEFAULT FALSE,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS course_id TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS meeting_number INT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS course_name TEXT;
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS module_label TEXT;

-- Notifikasi pribadi: bila target_user diisi (NIM/NIP), hanya pengguna itu yang melihatnya.
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS target_user TEXT;
CREATE INDEX IF NOT EXISTS idx_notifications_target_user
    ON public.notifications (target_role, target_user);

-- Status dibaca per pengguna (kolom is_read lama dipakai bersama satu peran).
CREATE TABLE IF NOT EXISTS public.notification_reads (
    notification_id UUID NOT NULL REFERENCES public.notifications(id) ON DELETE CASCADE,
    user_identifier TEXT NOT NULL,
    read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (notification_id, user_identifier)
);

CREATE INDEX IF NOT EXISTS idx_notifications_role_created
    ON public.notifications(target_role, created_at DESC);

INSERT INTO public.notifications (target_role, icon, title, body, target_key, important, is_read, created_at)
SELECT * FROM (VALUES
    ('praktikan', 'qrcode', 'Presensi Berlangsung', 'Praktikum Pemrograman Mobile • Lab Jaringan 1 sedang dibuka oleh Andi Pratama', 'presensi', TRUE, FALSE, NOW() - INTERVAL '5 minutes'),
    ('praktikan', 'bullhorn_outline', 'Pemindahan Jadwal Praktikum', 'Machine Learning Kelas C pindah ke Kam, 01 Okt • 13:00 di Lab Jaringan 3', 'pengumuman', TRUE, FALSE, NOW() - INTERVAL '2 hours'),
    ('praktikan', 'clipboard', 'Batas Unggah Tugas 4', 'Kumpulkan laporan & tautan repositori Pemrograman Mobile sebelum 10:30 WIB', 'editTugas', FALSE, FALSE, NOW() - INTERVAL '4 hours'),
    ('praktikan', 'trophy', 'Nilai Modul 3 Tersedia', 'Nilai Layout & Navigasi (88) telah diterbitkan oleh asisten', 'detailNilai', FALSE, TRUE, NOW() - INTERVAL '1 day'),
    ('aslab', 'file', 'Pengajuan Izin Menunggu', 'Rina Novita mengajukan Izin Sakit untuk Pertemuan 5 Pemrograman Mobile', 'persetujuanIzin', TRUE, FALSE, NOW() - INTERVAL '10 minutes'),
    ('aslab', 'clipboard', 'Tugas 4 Perlu Dievaluasi', '20 praktikan telah mengumpulkan Tugas 4 Praktikum Pemrograman Mobile', 'evaluasi', TRUE, FALSE, NOW() - INTERVAL '1 hour'),
    ('aslab', 'arrow_right_left', 'Permintaan Tukar Shift', 'Feri Gunawan meminta bertukar shift jaga minggu ini', 'shiftJaga', FALSE, FALSE, NOW() - INTERVAL '3 hours'),
    ('aslab', 'question', 'Hasil Kuis Pre-Test Modul 4', '22 dari 24 praktikan telah menyelesaikan kuis dengan rata-rata 78,5', 'hasilKuis', FALSE, TRUE, NOW() - INTERVAL '1 day'),
    ('laboran', 'wrench_outline', 'Tiket Kerusakan Baru', 'PC-12 Lab Jaringan 1 dilaporkan mengalami kendala monitor tidak tampil', 'tiket', TRUE, FALSE, NOW() - INTERVAL '15 minutes'),
    ('laboran', 'calendar', '2 Pengajuan Pemakaian Ruangan', 'Menunggu persetujuan jadwal pemakaian Lab Komputer 2 & Lab Jaringan 1', 'ruangan', TRUE, FALSE, NOW() - INTERVAL '2 hours'),
    ('laboran', 'key', 'Presensi Asisten On-Duty', 'Andi Pratama & Feri Gunawan telah verifikasi kehadiran di laboratorium', 'presensi', FALSE, TRUE, NOW() - INTERVAL '1 day'),
    ('dosen', 'triangle_alert', 'Peringatan Dini: 3 Praktikan', 'Kehadiran atau nilai di bawah batas minimal pada grup praktikum diampu', 'peringatan', TRUE, FALSE, NOW() - INTERVAL '5 minutes'),
    ('dosen', 'circle_check', 'Modul 4 Selesai Dinilai', 'Praktikum Pemrograman Mobile Kelas C • Andi Pratama', 'validasi', FALSE, FALSE, NOW() - INTERVAL '1 hour'),
    ('dosen', 'chart_bar', 'Rekap Kehadiran Minggu ke-4', 'Rata-rata kehadiran 91% dari 4 grup praktikum aktif', 'laporan', FALSE, FALSE, NOW() - INTERVAL '2 hours'),
    ('dosen', 'clipboard', 'Nilai Akhir Siap Divalidasi', 'Pemrograman Mobile Kelas C menunggu validasi dosen pengampu', 'validasi', TRUE, TRUE, NOW() - INTERVAL '1 day')
) AS seed(target_role, icon, title, body, target_key, important, is_read, created_at)
WHERE NOT EXISTS (SELECT 1 FROM public.notifications LIMIT 1);

-- BAGIAN 9: SUPABASE STORAGE BUCKET (`itlg-uploads`) UNTUK UPLOAD BERKAS NYATA

INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('itlg-uploads', 'itlg-uploads', TRUE, 20971520)
ON CONFLICT (id) DO UPDATE SET
    public = TRUE,
    file_size_limit = 20971520;

DROP POLICY IF EXISTS "itlg_uploads_select_all" ON storage.objects;
CREATE POLICY "itlg_uploads_select_all"
    ON storage.objects FOR SELECT USING (bucket_id = 'itlg-uploads');

-- Baca tetap publik (bucket publik); tulis/ubah/hapus hanya pengguna login.
DROP POLICY IF EXISTS "itlg_uploads_insert_all" ON storage.objects;
DROP POLICY IF EXISTS "itlg_uploads_update_all" ON storage.objects;
DROP POLICY IF EXISTS "itlg_uploads_delete_all" ON storage.objects;

DROP POLICY IF EXISTS "itlg_uploads_insert_auth" ON storage.objects;
CREATE POLICY "itlg_uploads_insert_auth"
    ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'itlg-uploads');

DROP POLICY IF EXISTS "itlg_uploads_update_auth" ON storage.objects;
CREATE POLICY "itlg_uploads_update_auth"
    ON storage.objects FOR UPDATE TO authenticated
    USING (bucket_id = 'itlg-uploads')
    WITH CHECK (bucket_id = 'itlg-uploads');

DROP POLICY IF EXISTS "itlg_uploads_delete_auth" ON storage.objects;
CREATE POLICY "itlg_uploads_delete_auth"
    ON storage.objects FOR DELETE TO authenticated
    USING (bucket_id = 'itlg-uploads');

-- BAGIAN 10: ROW LEVEL SECURITY (RLS) & SUPABASE REALTIME PUBLICATION
-- Semua tabel hanya bisa dibaca/ditulis pengguna yang sudah login (authenticated).
-- Tanpa login (kunci publik di APK saja) hasilnya kosong. profiles diatur di BAGIAN 1
-- (baca publik untuk mencari email dari NIM/NIP saat login).

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
        'labs',
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
        'grade_change_logs',
        'assistant_followups',
        'report_downloads',
        'notifications',
        'quiz_questions',
        'notification_reads'
    ] LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', tbl);
        -- Kebijakan lama "semua orang" (versi sebelumnya) dihapus.
        EXECUTE format('DROP POLICY IF EXISTS "%s_select_all" ON public.%I', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_insert_all" ON public.%I', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_update_all" ON public.%I', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_delete_all" ON public.%I', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_rw_auth" ON public.%I', tbl, tbl);
        EXECUTE format(
            'CREATE POLICY "%s_rw_auth" ON public.%I FOR ALL TO authenticated USING (true) WITH CHECK (true)',
            tbl, tbl);

        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        EXCEPTION WHEN duplicate_object OR undefined_object THEN NULL;
        END;
    END LOOP;
END $$;

-- BAGIAN 11: PENYELARASAN DATABASE LAMA (aman dijalankan ulang)
-- Untuk database yang dibuat dari versi schema sebelumnya. Pada database baru
-- semua perintah di bawah tidak mengubah apa pun.

-- Nama ruangan lama → master Lab Jaringan 1–4 (riwayat tiket/sesi dibiarkan).
UPDATE public.praktikum_courses   SET room = 'Lab Jaringan 1' WHERE room = 'Lab Komputer 1';
UPDATE public.praktikum_courses   SET room = 'Lab Jaringan 3' WHERE room = 'Lab AI & Data';
UPDATE public.praktikum_schedules SET room = 'Lab Jaringan 1', updated_at = NOW() WHERE room = 'Lab Komputer 1';
UPDATE public.praktikum_schedules SET room = 'Lab Jaringan 3', updated_at = NOW() WHERE room = 'Lab AI & Data';
UPDATE public.lab_shifts          SET room = 'Lab Jaringan 1', updated_at = NOW() WHERE room = 'Lab Komputer 1';
UPDATE public.lab_shifts          SET room = 'Lab Jaringan 3', updated_at = NOW() WHERE room = 'Lab AI & Data';

-- Baris seed ganda (schema lama dijalankan berulang): sisakan yang tertua.
DELETE FROM public.leave_requests
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (
            PARTITION BY course_id, meeting_number, user_identifier, leave_type, note
            ORDER BY created_at, id) AS rn
        FROM public.leave_requests
    ) x WHERE rn > 1
);
DELETE FROM public.announcements
WHERE id IN (
    SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY title, body ORDER BY created_at, id) AS rn
        FROM public.announcements
    ) x WHERE rn > 1
);

-- Sesi contoh lama (seed versi sebelumnya: pemob-p5 di Lab Komputer 1, status aktif)
-- ditutup. Sesi yang dibuat Aslab dari aplikasi tidak tersentuh.
UPDATE public.attendance_sessions
SET status = 'closed', ended_at = NOW()
WHERE id = 'pemob-p5' AND lab_name = 'Lab Komputer 1' AND status = 'active';

-- Meja "terisi" di lab yang tidak punya sesi presensi aktif dilepas.
UPDATE public.lab_desks d
SET status = 'available', booked_by_user_id = NULL, booked_by_name = NULL,
    booked_at = NULL, updated_at = NOW()
WHERE d.status = 'taken'
  AND NOT EXISTS (SELECT 1 FROM public.attendance_sessions s
                  WHERE s.status = 'active' AND s.lab_name = d.lab_name);
UPDATE public.desk_bookings b
SET status = 'released'
WHERE b.status = 'active'
  AND NOT EXISTS (SELECT 1 FROM public.attendance_sessions s
                  WHERE s.status = 'active' AND s.lab_name = b.lab_name);

-- Cek akhir (tab Results): semua kolom "masalah" harus 0.
SELECT 'ruangan di luar master labs' AS cek, count(*) AS masalah FROM (
    SELECT room FROM public.praktikum_courses   WHERE room NOT IN (SELECT name FROM public.labs)
    UNION ALL
    SELECT room FROM public.praktikum_schedules WHERE room NOT IN (SELECT name FROM public.labs)
    UNION ALL
    SELECT room FROM public.lab_shifts          WHERE room NOT IN (SELECT name FROM public.labs)
) r
UNION ALL
SELECT 'meja terisi tanpa sesi aktif', count(*) FROM public.lab_desks d
WHERE d.status = 'taken' AND NOT EXISTS (
    SELECT 1 FROM public.attendance_sessions s WHERE s.status = 'active' AND s.lab_name = d.lab_name)
UNION ALL
SELECT 'profil bukan @students.usu.ac.id', count(*) FROM public.profiles
WHERE email !~* '^[A-Za-z0-9._%+-]+@students\.usu\.ac\.id$';
