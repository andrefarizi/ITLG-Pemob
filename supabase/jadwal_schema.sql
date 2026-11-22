-- =============================================================================
-- SKEMA BASIS DATA JADWAL PRAKTIKUM & PENGUMUMAN PERUBAHAN JADWAL
-- ITLG MOBILE - SINKRONISASI LINTAS ROLE (PRAKTIKAN ↔ ASLAB ↔ LABORAN ↔ DOSEN)
-- =============================================================================
-- Petunjuk Penggunaan:
-- 1. Buka dashboard project Supabase Anda: https://supabase.com/dashboard
-- 2. Masuk ke menu "SQL Editor" di bilah kiri.
-- 3. Tempel (paste) seluruh isi skrip ini, lalu klik tombol "Run".
-- =============================================================================

-- 1. Tabel Jadwal Praktikum (public.praktikum_schedules)
CREATE TABLE IF NOT EXISTS public.praktikum_schedules (
    id TEXT PRIMARY KEY,
    course_id TEXT NOT NULL,
    course_name TEXT NOT NULL,
    kelas TEXT NOT NULL DEFAULT 'Kelas C',
    day_index INT NOT NULL CHECK (day_index BETWEEN 0 AND 5), -- 0: Sen .. 5: Sab
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

-- 2. Tabel Pengumuman & Perubahan Jadwal (public.announcements)
CREATE TABLE IF NOT EXISTS public.announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id TEXT,
    category INT NOT NULL DEFAULT 1 CHECK (category IN (1, 2, 3)), -- 1: Perubahan Jadwal, 2: Umum, 3: Penting
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

-- 3. Tabel Permintaan & Approval Peminjaman Ruangan Lab (public.room_booking_requests)
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

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================
ALTER TABLE public.praktikum_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_booking_requests ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['praktikum_schedules', 'announcements', 'room_booking_requests'] LOOP
        EXECUTE format('DROP POLICY IF EXISTS "%s_select_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_select_all" ON public.%I FOR SELECT USING (true)', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_insert_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_insert_all" ON public.%I FOR INSERT WITH CHECK (true)', tbl, tbl);
        EXECUTE format('DROP POLICY IF EXISTS "%s_update_all" ON public.%I', tbl, tbl);
        EXECUTE format('CREATE POLICY "%s_update_all" ON public.%I FOR UPDATE USING (true) WITH CHECK (true)', tbl, tbl);
    END LOOP;
END $$;

-- =============================================================================
-- AKTIFKAN SUPABASE REALTIME
-- =============================================================================
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['praktikum_schedules', 'announcements', 'room_booking_requests'] LOOP
        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        EXCEPTION WHEN duplicate_object THEN NULL;
        END;
    END LOOP;
END $$;

-- =============================================================================
-- SEED DATA AWAL 4 JADWAL PRAKTIKUM SEMESTER GANJIL 2026/2027
-- =============================================================================
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
