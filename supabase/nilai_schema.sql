-- =============================================================================
-- SKEMA BASIS DATA NILAI, VALIDASI DOSEN, SANGGAHAN & TINDAK LANJUT
-- ITLG MOBILE - SINKRONISASI LINTAS ROLE (PRAKTIKAN ↔ ASLAB ↔ DOSEN)
-- =============================================================================
-- Jalankan di Supabase Dashboard -> SQL Editor -> Run
-- =============================================================================

-- 1. Tabel Status Validasi & Revisi Nilai Akhir per Praktikum (Dosen ↔ Aslab ↔ Praktikan)
CREATE TABLE IF NOT EXISTS public.grade_validations (
    course_id TEXT PRIMARY KEY,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'revision_requested', 'validated')),
    revision_part TEXT,
    revision_note TEXT,
    validated_by TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Tabel Sanggahan Nilai Praktikan (Praktikan → Aslab & Dosen)
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

-- 3. Tabel Tindak Lanjut Dosen ke Asisten (Dosen → Aslab)
CREATE TABLE IF NOT EXISTS public.assistant_followups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_nim TEXT NOT NULL,
    student_name TEXT NOT NULL,
    assistant_name TEXT NOT NULL,
    followup_type TEXT NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================
ALTER TABLE public.grade_validations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grade_appeals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assistant_followups ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['grade_validations', 'grade_appeals', 'assistant_followups'] LOOP
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
    FOREACH tbl IN ARRAY ARRAY['grade_validations', 'grade_appeals', 'assistant_followups'] LOOP
        BEGIN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
        EXCEPTION WHEN duplicate_object THEN NULL;
        END;
    END LOOP;
END $$;

-- Seed status validasi awal untuk 4 praktikum
INSERT INTO public.grade_validations (course_id, status) VALUES
    ('pemob', 'pending'),
    ('desain', 'pending'),
    ('adj', 'validated'),
    ('ml', 'validated')
ON CONFLICT (course_id) DO NOTHING;
