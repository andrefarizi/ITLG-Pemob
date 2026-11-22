-- =============================================================================
-- SKEMA BASIS DATA NOTIFIKASI LINTAS ROLE (ITLG MOBILE)
-- PRAKTIKAN ↔ ASLAB ↔ LABORAN ↔ DOSEN
-- =============================================================================
-- Jalankan di Supabase Dashboard -> SQL Editor -> Run
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

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_all" ON public.notifications;
CREATE POLICY "notifications_select_all"
    ON public.notifications FOR SELECT USING (true);

DROP POLICY IF EXISTS "notifications_insert_all" ON public.notifications;
CREATE POLICY "notifications_insert_all"
    ON public.notifications FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "notifications_update_all" ON public.notifications;
CREATE POLICY "notifications_update_all"
    ON public.notifications FOR UPDATE USING (true) WITH CHECK (true);

DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- Seed notifikasi awal per role (hanya bila tabel masih kosong)
INSERT INTO public.notifications (target_role, icon, title, body, target_key, important, is_read, created_at)
SELECT * FROM (VALUES
    -- Praktikan
    ('praktikan', 'qrcode', 'Presensi Berlangsung', 'Praktikum Pemrograman Mobile • Lab Komputer 1 sedang dibuka oleh Andi Pratama', 'presensi', TRUE, FALSE, NOW() - INTERVAL '5 minutes'),
    ('praktikan', 'bullhorn_outline', 'Pemindahan Jadwal Praktikum', 'Machine Learning Kelas C pindah ke Kam, 01 Okt • 13:00 di Lab AI & Data', 'pengumuman', TRUE, FALSE, NOW() - INTERVAL '2 hours'),
    ('praktikan', 'clipboard', 'Batas Unggah Tugas 4', 'Kumpulkan laporan & tautan repositori Pemrograman Mobile sebelum 10:30 WIB', 'editTugas', FALSE, FALSE, NOW() - INTERVAL '4 hours'),
    ('praktikan', 'trophy', 'Nilai Modul 3 Tersedia', 'Nilai Layout & Navigasi (88) telah diterbitkan oleh asisten', 'detailNilai', FALSE, TRUE, NOW() - INTERVAL '1 day'),

    -- Aslab
    ('aslab', 'file', 'Pengajuan Izin Menunggu', 'Rina Novita mengajukan Izin Sakit untuk Pertemuan 5 Pemrograman Mobile', 'persetujuanIzin', TRUE, FALSE, NOW() - INTERVAL '10 minutes'),
    ('aslab', 'clipboard', 'Tugas 4 Perlu Dievaluasi', '20 praktikan telah mengumpulkan Tugas 4 Praktikum Pemrograman Mobile', 'evaluasi', TRUE, FALSE, NOW() - INTERVAL '1 hour'),
    ('aslab', 'arrow_right_left', 'Permintaan Tukar Shift', 'Feri Gunawan meminta bertukar shift jaga minggu ini', 'shiftJaga', FALSE, FALSE, NOW() - INTERVAL '3 hours'),
    ('aslab', 'question', 'Hasil Kuis Pre-Test Modul 4', '22 dari 24 praktikan telah menyelesaikan kuis dengan rata-rata 78,5', 'hasilKuis', FALSE, TRUE, NOW() - INTERVAL '1 day'),

    -- Laboran
    ('laboran', 'wrench_outline', 'Tiket Kerusakan Baru', 'PC-12 Lab Komputer 1 dilaporkan mengalami kendala monitor tidak tampil', 'tiket', TRUE, FALSE, NOW() - INTERVAL '15 minutes'),
    ('laboran', 'calendar', '2 Pengajuan Pemakaian Ruangan', 'Menunggu persetujuan jadwal pemakaian Lab Komputer 2 & Lab Jaringan 1', 'ruangan', TRUE, FALSE, NOW() - INTERVAL '2 hours'),
    ('laboran', 'key', 'Presensi Asisten On-Duty', 'Andi Pratama & Feri Gunawan telah verifikasi kehadiran di laboratorium', 'presensi', FALSE, TRUE, NOW() - INTERVAL '1 day'),

    -- Dosen
    ('dosen', 'triangle_alert', 'Peringatan Dini: 3 Praktikan', 'Kehadiran atau nilai di bawah batas minimal pada grup praktikum diampu', 'peringatan', TRUE, FALSE, NOW() - INTERVAL '5 minutes'),
    ('dosen', 'circle_check', 'Modul 4 Selesai Dinilai', 'Praktikum Pemrograman Mobile Kelas C • Andi Pratama', 'validasi', FALSE, FALSE, NOW() - INTERVAL '1 hour'),
    ('dosen', 'chart_bar', 'Rekap Kehadiran Minggu ke-4', 'Rata-rata kehadiran 91% dari 4 grup praktikum aktif', 'laporan', FALSE, FALSE, NOW() - INTERVAL '2 hours'),
    ('dosen', 'clipboard', 'Nilai Akhir Siap Divalidasi', 'Pemrograman Mobile Kelas C menunggu validasi dosen pengampu', 'validasi', TRUE, TRUE, NOW() - INTERVAL '1 day')
) AS seed(target_role, icon, title, body, target_key, important, is_read, created_at)
WHERE NOT EXISTS (SELECT 1 FROM public.notifications LIMIT 1);
