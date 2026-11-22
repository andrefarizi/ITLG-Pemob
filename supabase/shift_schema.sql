-- =============================================================================
-- SKEMA BASIS DATA SHIFT JAGA, TUKAR SHIFT & PRESENSI ASISTEN - ITLG MOBILE
-- =============================================================================
-- Petunjuk Penggunaan:
-- 1. Buka dashboard project Supabase Anda: https://supabase.com/dashboard
-- 2. Masuk ke menu "SQL Editor" di bilah kiri.
-- 3. Tempel (paste) seluruh isi skrip ini, lalu klik tombol "Run".
-- =============================================================================

-- 1. Tabel Jadwal Shift Jaga & Presensi Asisten (public.lab_shifts)
CREATE TABLE IF NOT EXISTS public.lab_shifts (
    id TEXT PRIMARY KEY,
    day_index INT NOT NULL CHECK (day_index BETWEEN 0 AND 5), -- 0:Sen .. 5:Sab
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

-- 2. Tabel Permintaan & Riwayat Tukar Shift (public.shift_swap_requests)
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

-- 3. Tabel Kode Akses Presensi Shift Asisten (public.assistant_access_codes)
CREATE TABLE IF NOT EXISTS public.assistant_access_codes (
    id TEXT PRIMARY KEY DEFAULT 'today',
    code TEXT NOT NULL,
    valid_until TEXT NOT NULL DEFAULT '17:00 WIB',
    generated_by TEXT NOT NULL DEFAULT 'Laboran',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) - AKSES SINKRONISASI ANTAR ROLE
-- =============================================================================
ALTER TABLE public.lab_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shift_swap_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assistant_access_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lab_shifts_select_all" ON public.lab_shifts;
CREATE POLICY "lab_shifts_select_all" ON public.lab_shifts FOR SELECT USING (true);
DROP POLICY IF EXISTS "lab_shifts_insert_all" ON public.lab_shifts;
CREATE POLICY "lab_shifts_insert_all" ON public.lab_shifts FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "lab_shifts_update_all" ON public.lab_shifts;
CREATE POLICY "lab_shifts_update_all" ON public.lab_shifts FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "shift_swaps_select_all" ON public.shift_swap_requests;
CREATE POLICY "shift_swaps_select_all" ON public.shift_swap_requests FOR SELECT USING (true);
DROP POLICY IF EXISTS "shift_swaps_insert_all" ON public.shift_swap_requests;
CREATE POLICY "shift_swaps_insert_all" ON public.shift_swap_requests FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "shift_swaps_update_all" ON public.shift_swap_requests;
CREATE POLICY "shift_swaps_update_all" ON public.shift_swap_requests FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "access_codes_select_all" ON public.assistant_access_codes;
CREATE POLICY "access_codes_select_all" ON public.assistant_access_codes FOR SELECT USING (true);
DROP POLICY IF EXISTS "access_codes_insert_all" ON public.assistant_access_codes;
CREATE POLICY "access_codes_insert_all" ON public.assistant_access_codes FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "access_codes_update_all" ON public.assistant_access_codes;
CREATE POLICY "access_codes_update_all" ON public.assistant_access_codes FOR UPDATE USING (true) WITH CHECK (true);

-- =============================================================================
-- AKTIFKAN SUPABASE REALTIME
-- =============================================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.lab_shifts;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.shift_swap_requests;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.assistant_access_codes;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================================================
-- SEED DATA AWAL (SESUAI DESAIN FIGMA)
-- =============================================================================
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
