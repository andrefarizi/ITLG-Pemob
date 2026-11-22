-- =============================================================================
-- SKEMA BASIS DATA MEJA PRAKTIKUM, BOOKING & TIKET KERUSAKAN - ITLG MOBILE
-- =============================================================================
-- Petunjuk Penggunaan:
-- 1. Buka dashboard project Supabase Anda: https://supabase.com/dashboard
-- 2. Masuk ke menu "SQL Editor" di bilah kiri.
-- 3. Tempel (paste) seluruh isi skrip ini, lalu klik tombol "Run".
-- =============================================================================

-- 1. Tabel Master Meja & PC per Laboratorium (public.lab_desks)
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

-- 2. Tabel Riwayat Booking Meja Praktikum (public.desk_bookings)
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

-- 3. Tabel Tiket Laporan Kerusakan Meja & Perangkat (public.lab_tickets)
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
    status INT NOT NULL DEFAULT 0 CHECK (status IN (0, 1, 2)), -- 0: Reported, 1: In Progress, 2: Resolved
    handling_note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_lab_tickets_lab_desk ON public.lab_tickets(lab_name, desk_number);
CREATE INDEX IF NOT EXISTS idx_lab_tickets_status ON public.lab_tickets(status);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) - AKSES SINKRONISASI ANTAR ROLE
-- =============================================================================
ALTER TABLE public.lab_desks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.desk_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lab_tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "lab_desks_select_all" ON public.lab_desks;
CREATE POLICY "lab_desks_select_all" ON public.lab_desks FOR SELECT USING (true);
DROP POLICY IF EXISTS "lab_desks_insert_all" ON public.lab_desks;
CREATE POLICY "lab_desks_insert_all" ON public.lab_desks FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "lab_desks_update_all" ON public.lab_desks;
CREATE POLICY "lab_desks_update_all" ON public.lab_desks FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "desk_bookings_select_all" ON public.desk_bookings;
CREATE POLICY "desk_bookings_select_all" ON public.desk_bookings FOR SELECT USING (true);
DROP POLICY IF EXISTS "desk_bookings_insert_all" ON public.desk_bookings;
CREATE POLICY "desk_bookings_insert_all" ON public.desk_bookings FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "desk_bookings_update_all" ON public.desk_bookings;
CREATE POLICY "desk_bookings_update_all" ON public.desk_bookings FOR UPDATE USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "lab_tickets_select_all" ON public.lab_tickets;
CREATE POLICY "lab_tickets_select_all" ON public.lab_tickets FOR SELECT USING (true);
DROP POLICY IF EXISTS "lab_tickets_insert_all" ON public.lab_tickets;
CREATE POLICY "lab_tickets_insert_all" ON public.lab_tickets FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "lab_tickets_update_all" ON public.lab_tickets;
CREATE POLICY "lab_tickets_update_all" ON public.lab_tickets FOR UPDATE USING (true) WITH CHECK (true);

-- =============================================================================
-- AKTIFKAN SUPABASE REALTIME UNTUK SINKRONISASI LANGSUNG ANTAR PERANGKAT/ROLE
-- =============================================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.lab_desks;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.lab_tickets;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =============================================================================
-- SEED DATA AWAL (SESUAI DESAIN FIGMA)
-- =============================================================================

-- Seed 30 meja untuk Lab Komputer 1
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

-- Seed awal Lab Jaringan 2 & Lab Multimedia (untuk Inventaris Laboran)
INSERT INTO public.lab_desks (lab_name, desk_number, pc_code, spec, status) VALUES
    ('Lab Jaringan 2', 1, 'PC-01', 'Core i5-12400 • 16 GB • SSD 512 GB', 'available'),
    ('Lab Jaringan 2', 2, 'PC-02', 'Core i5-12400 • 16 GB • SSD 512 GB', 'available'),
    ('Lab Jaringan 2', 12, 'PC-12', 'Core i5-12400 • 16 GB • SSD 512 GB', 'broken'),
    ('Lab Multimedia', 1, 'PC-01', 'Core i5-12400 • 16 GB • SSD 512 GB', 'available'),
    ('Lab Multimedia', 2, 'PC-02', 'Core i5-12400 • 16 GB • SSD 512 GB', 'available'),
    ('Lab Multimedia', 12, 'PC-12', 'Core i5-12400 • 16 GB • SSD 512 GB', 'broken')
ON CONFLICT (lab_name, desk_number) DO NOTHING;

-- Seed 3 tiket awal sesuai Figma
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
