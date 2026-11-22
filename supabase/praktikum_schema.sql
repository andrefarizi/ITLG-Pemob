-- =============================================================================
-- SKEMA BASIS DATA PRAKTIKUM (4 MATA KULIAH), MATERI, TUGAS, KUIS & RATING
-- ITLG MOBILE - SEMESTER GANJIL 2026/2027
-- =============================================================================
-- Petunjuk Penggunaan:
-- 1. Buka dashboard project Supabase Anda: https://supabase.com/dashboard
-- 2. Masuk ke menu "SQL Editor" di bilah kiri.
-- 3. Tempel (paste) seluruh isi skrip ini, lalu klik tombol "Run".
-- =============================================================================

-- 1. Tabel Daftar Praktikum (public.praktikum_courses)
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

-- 2. Tabel Daftar Pertemuan per Praktikum (public.praktikum_meetings)
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

-- 3. Tabel Pengumpulan Tugas Praktikan (public.tugas_submissions)
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

-- 4. Tabel Hasil Kuis Pre-Test Praktikan (public.kuis_attempts)
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

-- 5. Tabel Penilaian / Rating Asisten (public.asisten_ratings)
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

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) - SINKRONISASI ANTAR ROLE
-- =============================================================================
ALTER TABLE public.praktikum_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.praktikum_meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tugas_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kuis_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.asisten_ratings ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['praktikum_courses', 'praktikum_meetings', 'tugas_submissions', 'kuis_attempts', 'asisten_ratings'] LOOP
        EXECUTE format('DROP POLICY IF EXISTS "%s_select_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_select_all" ON public.%I FOR SELECT USING (true)', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_insert_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_insert_all" ON public.%I FOR INSERT WITH CHECK (true)', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_update_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_update_all" ON public.%I FOR UPDATE USING (true) WITH CHECK (true)', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_delete_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_delete_all" ON public.%I FOR DELETE USING (true)', tbl, tbl);
    END LOOP;
END $$;

-- =============================================================================
-- AKTIFKAN SUPABASE REALTIME
-- =============================================================================
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['praktikum_courses', 'praktikum_meetings', 'tugas_submissions', 'kuis_attempts', 'asisten_ratings'] LOOP
        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        EXCEPTION WHEN duplicate_object THEN NULL;
        END;
    END LOOP;
END $$;

-- =============================================================================
-- SEED DATA 4 PRAKTIKUM SEMESTER GANJIL 2026/2027
-- =============================================================================
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

-- Seed pertemuan 1–5 untuk 4 praktikum
INSERT INTO public.praktikum_meetings (
    id, course_id, meeting_number, module_title, date_label, description,
    materi_title, materi_file, tugas_title, tugas_deadline, kuis_title,
    attend_status, attend_note_icon, attend_note, izin_file
) VALUES
-- Pemrograman Mobile
('pemob-m5', 'pemob', 5, 'Modul 5 • Navigasi & Routing', 'Sen, 05 Okt 2026 • 08:00–09:40 WIB', 'Penerapan Navigator, Named Routes, dan pengiriman argumen antar halaman.', 'Panduan Navigasi Flutter', 'Modul_5_Navigasi.pdf', 'Tugas 5 : Aplikasi Multi Halaman', 'Batas 10:30 WIB, 12 Okt 2026', 'Pre-Test Modul 5 : Navigasi', 'upcoming', NULL, NULL, NULL),
('pemob-m4', 'pemob', 4, 'Modul 4 • State Management', 'Sen, 28 Sep 2026 • 08:00–09:40 WIB', 'Pembahasan State Management Flutter secara mendalam: setState, ChangeNotifier, dan Provider.', 'Panduan State Management Flutter', 'Panduan_State_Management_Flutter.pdf', 'Tugas 4 : Implementasi State Management', 'Batas 10:30 WIB, 29 Sep 2026', 'Pre-Test Modul 4 : State Management', 'hadir', 'qrcode', 'Tercatat 08:03 WIB melalui pindai QR', NULL),
('pemob-m3', 'pemob', 3, 'Modul 3 • Layout & Navigasi', 'Sen, 21 Sep 2026 • 08:00–09:40 WIB', 'Penyusunan layout responsif dengan Row, Column, Stack, dan ListView.', 'Materi Layout & Navigasi', 'Modul_3_Layout.pdf', 'Tugas 3 : Halaman Login', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 08:01 WIB melalui tombol hadir & lokasi', NULL),
('pemob-m2', 'pemob', 2, 'Modul 2 • Widget Dasar', 'Sen, 14 Sep 2026 • 08:00–09:40 WIB', 'Pengenalan StatelessWidget, StatefulWidget, dan komponen UI dasar.', 'Materi Widget Dasar', 'Modul_2_Widget.pdf', 'Tugas 2 : Profil Mahasiswa', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'izin', NULL, NULL, 'surat_dokter.pdf'),
('pemob-m1', 'pemob', 1, 'Modul 1 • Pengenalan Flutter', 'Sen, 07 Sep 2026 • 08:00–09:40 WIB', 'Instalasi Flutter SDK, emulator Android, dan struktur proyek Dart.', 'Materi Pengenalan Flutter', 'Modul_1_Flutter.pdf', 'Tugas 1 : Hello Flutter', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 07:58 WIB melalui pindai QR', NULL),

-- Desain Interaksi
('desain-m5', 'desain', 5, 'Modul 5 • Design System', 'Sen, 05 Okt 2026 • 13:00–14:40 WIB', 'Membangun token warna, tipografi, dan pustaka komponen terstandar.', 'Panduan Design System', 'Modul_5_Design_System.pdf', 'Tugas 5 : Design System Mini', 'Batas 10:30 WIB, 12 Okt 2026', 'Pre-Test Modul 5 : Design System', 'upcoming', NULL, NULL, NULL),
('desain-m4', 'desain', 4, 'Modul 4 • Figma Management', 'Sen, 28 Sep 2026 • 13:00–14:40 WIB', 'Pembahasan materi Figma secara mendalam: komponen, variant, dan auto layout.', 'Panduan Penggunaan Figma', 'Panduan_Penggunaan_Figma.pdf', 'Tugas 4 : Pembuatan Prototype Figma', 'Batas 10:30 WIB, 29 Sep 2026', 'Pre-Test Modul 4 : Figma Management', 'hadir', 'qrcode', 'Tercatat 13:02 WIB melalui pindai QR', NULL),
('desain-m3', 'desain', 3, 'Modul 3 • Prototyping Dasar', 'Sen, 21 Sep 2026 • 13:00–14:40 WIB', 'Membuat alur interaksi interaktif dan transisi smart animate.', 'Materi Prototyping Dasar', 'Modul_3_Prototyping.pdf', 'Tugas 3 : Alur Login Interaktif', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 13:00 WIB melalui tombol hadir & lokasi', NULL),
('desain-m2', 'desain', 2, 'Modul 2 • Wireframing', 'Sen, 14 Sep 2026 • 13:00–14:40 WIB', 'Perancangan wireframe low-fidelity dan hierarki informasi.', 'Materi Wireframing', 'Modul_2_Wireframing.pdf', 'Tugas 2 : Wireframe Aplikasi Kampus', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'hadir', 'qrcode', 'Tercatat 12:58 WIB melalui pindai QR', NULL),
('desain-m1', 'desain', 1, 'Modul 1 • Pengenalan Figma', 'Sen, 07 Sep 2026 • 13:00–14:40 WIB', 'Pengenalan workspace Figma, frame, grid, dan constraints.', 'Materi Pengenalan Figma', 'Modul_1_Figma.pdf', 'Tugas 1 : Eksplorasi Frame Figma', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 13:01 WIB melalui pindai QR', NULL),

-- Analisis Desain Jaringan
('adj-m5', 'adj', 5, 'Modul 5 • Dynamic Routing OSPF', 'Rab, 07 Okt 2026 • 10:00–11:40 WIB', 'Konfigurasi routing dinamis OSPF single-area dan verifikasi neighbor table.', 'Panduan Routing OSPF', 'Modul_5_OSPF.pdf', 'Tugas 5 : Simulasi OSPF Multi-Router', 'Batas 10:30 WIB, 14 Okt 2026', 'Pre-Test Modul 5 : OSPF', 'upcoming', NULL, NULL, NULL),
('adj-m4', 'adj', 4, 'Modul 4 • VLAN & Inter-VLAN Routing', 'Rab, 30 Sep 2026 • 10:00–11:40 WIB', 'Perancangan segmentasi VLAN, trunking 802.1Q, dan Router-on-a-Stick.', 'Panduan Konfigurasi VLAN & Trunking', 'Panduan_VLAN_InterVLAN_Routing.pdf', 'Tugas 4 : Topologi Multi-VLAN Kampus', 'Batas 10:30 WIB, 01 Okt 2026', 'Pre-Test Modul 4 : VLAN & Routing', 'hadir', 'qrcode', 'Tercatat 10:02 WIB melalui pindai QR', NULL),
('adj-m3', 'adj', 3, 'Modul 3 • Subnetting & VLSM', 'Rab, 23 Sep 2026 • 10:00–11:40 WIB', 'Perhitungan alamat IPv4, CIDR, dan efisiensi pembagian blok VLSM.', 'Materi Subnetting & VLSM', 'Modul_3_VLSM.pdf', 'Tugas 3 : Desain Alokasi IP Gedung', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 10:01 WIB melalui tombol hadir & lokasi', NULL),
('adj-m2', 'adj', 2, 'Modul 2 • Topologi & Analisis Trafik', 'Rab, 16 Sep 2026 • 10:00–11:40 WIB', 'Pemetaan kebutuhan bandwidth, topologi hirarkis, dan inspeksi Wireshark.', 'Materi Topologi & Wireshark', 'Modul_2_Trafik.pdf', 'Tugas 2 : Capture Paket Wireshark', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'hadir', 'qrcode', 'Tercatat 09:59 WIB melalui pindai QR', NULL),
('adj-m1', 'adj', 1, 'Modul 1 • Pengenalan Desain Jaringan', 'Rab, 09 Sep 2026 • 10:00–11:40 WIB', 'Model OSI, TCP/IP, dan simulasi jaringan dasar di Packet Tracer.', 'Materi Pengenalan Jaringan', 'Modul_1_Jaringan.pdf', 'Tugas 1 : Simulasi LAN Dasar', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 10:00 WIB melalui pindai QR', NULL),

-- Machine Learning
('ml-m5', 'ml', 5, 'Modul 5 • Clustering & Unsupervised', 'Kam, 08 Okt 2026 • 13:00–14:40 WIB', 'Penerapan K-Means, Elbow Method, dan Silhouette Score untuk segmentasi data.', 'Panduan K-Means Clustering', 'Modul_5_Clustering.pdf', 'Tugas 5 : Segmentasi Pelanggan', 'Batas 10:30 WIB, 15 Okt 2026', 'Pre-Test Modul 5 : Clustering', 'upcoming', NULL, NULL, NULL),
('ml-m4', 'ml', 4, 'Modul 4 • Klasifikasi Supervised Learning', 'Kam, 01 Okt 2026 • 13:00–14:40 WIB', 'Implementasi Decision Tree, Random Forest, dan evaluasi confusion matrix dengan scikit-learn.', 'Panduan Klasifikasi Supervised ML', 'Panduan_Klasifikasi_ScikitLearn.pdf', 'Tugas 4 : Model Klasifikasi Dataset Medis', 'Batas 10:30 WIB, 02 Okt 2026', 'Pre-Test Modul 4 : Klasifikasi ML', 'hadir', 'qrcode', 'Tercatat 13:03 WIB melalui pindai QR', NULL),
('ml-m3', 'ml', 3, 'Modul 3 • Regresi Linear & Logistik', 'Kam, 24 Sep 2026 • 13:00–14:40 WIB', 'Pemodelan prediksi kontinu dengan Linear Regression dan evaluasi MSE/R2.', 'Materi Regresi Linear', 'Modul_3_Regresi.pdf', 'Tugas 3 : Prediksi Harga Properti', 'Sudah dinilai asisten', 'Pre-Test Modul 3', 'hadir', 'location', 'Tercatat 13:01 WIB melalui tombol hadir & lokasi', NULL),
('ml-m2', 'ml', 2, 'Modul 2 • Preprocessing & EDA', 'Kam, 17 Sep 2026 • 13:00–14:40 WIB', 'Pembersihan missing values, encoding fitur kategorikal, dan scaling data.', 'Materi Preprocessing Data', 'Modul_2_EDA.pdf', 'Tugas 2 : Pipeline Preprocessing', 'Sudah dinilai asisten', 'Pre-Test Modul 2', 'hadir', 'qrcode', 'Tercatat 12:59 WIB melalui pindai QR', NULL),
('ml-m1', 'ml', 1, 'Modul 1 • Pengenalan Python & NumPy', 'Kam, 10 Sep 2026 • 13:00–14:40 WIB', 'Manipulasi array NumPy, DataFrame Pandas, dan visualisasi Matplotlib.', 'Materi Python untuk ML', 'Modul_1_Python_ML.pdf', 'Tugas 1 : Eksplorasi Dataset CSV', 'Sudah dinilai asisten', 'Pre-Test Modul 1', 'hadir', 'qrcode', 'Tercatat 13:00 WIB melalui pindai QR', NULL)
ON CONFLICT (id) DO NOTHING;
