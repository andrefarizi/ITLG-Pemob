-- =============================================================================
-- SKEMA BASIS DATA PRESENSI, SESI AKTIF, STATUS KEHADIRAN & PERSETUJUAN IZIN
-- ITLG MOBILE - SINKRONISASI LINTAS ROLE (PRAKTIKAN ↔ ASLAB ↔ LABORAN)
-- =============================================================================
-- Petunjuk Penggunaan:
-- 1. Buka dashboard project Supabase Anda: https://supabase.com/dashboard
-- 2. Masuk ke menu "SQL Editor" di bilah kiri.
-- 3. Tempel (paste) seluruh isi skrip ini, lalu klik tombol "Run".
-- =============================================================================

-- 1. Tabel Sesi Presensi Aktif (public.attendance_sessions)
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

-- 2. Tabel Catatan Kehadiran Praktikan (public.attendance_records)
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

-- 3. Tabel Pengajuan & Persetujuan Izin (public.leave_requests)
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
    status INT NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2)), -- 0: Menunggu, 1: Disetujui, 2: Ditolak
    decided_by TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_leave_requests_status ON public.leave_requests(status);
CREATE INDEX IF NOT EXISTS idx_leave_requests_user ON public.leave_requests(user_identifier);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) - SINKRONISASI LINTAS ROLE
-- =============================================================================
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['attendance_sessions', 'attendance_records', 'leave_requests'] LOOP
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
    FOREACH tbl IN ARRAY ARRAY['attendance_sessions', 'attendance_records', 'leave_requests'] LOOP
        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        EXCEPTION WHEN duplicate_object THEN NULL;
        END;
    END LOOP;
END $$;

-- =============================================================================
-- SEED DATA AWAL PRESENSI & IZIN (SESUAI DESAIN FIGMA)
-- =============================================================================
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
