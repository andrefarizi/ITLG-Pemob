-- =============================================================================
-- SKEMA SUPABASE STORAGE BUCKET UNTUK UPLOAD BERKAS & FOTO (ITLG MOBILE)
-- Jalankan di Supabase Dashboard -> SQL Editor -> Run
-- =============================================================================

-- 1. Buat bucket publik `itlg-uploads` untuk Tugas, Modul, Lampiran Izin, & Foto Tiket
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('itlg-uploads', 'itlg-uploads', TRUE, 20971520) -- maks 20 MB per berkas
ON CONFLICT (id) DO UPDATE SET
    public = TRUE,
    file_size_limit = 20971520;

-- 2. Kebijakan akses Storage untuk upload & baca berkas lintas role
DROP POLICY IF EXISTS "itlg_uploads_select_all" ON storage.objects;
CREATE POLICY "itlg_uploads_select_all"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'itlg-uploads');

DROP POLICY IF EXISTS "itlg_uploads_insert_all" ON storage.objects;
CREATE POLICY "itlg_uploads_insert_all"
    ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'itlg-uploads');

DROP POLICY IF EXISTS "itlg_uploads_update_all" ON storage.objects;
CREATE POLICY "itlg_uploads_update_all"
    ON storage.objects FOR UPDATE
    USING (bucket_id = 'itlg-uploads')
    WITH CHECK (bucket_id = 'itlg-uploads');

DROP POLICY IF EXISTS "itlg_uploads_delete_all" ON storage.objects;
CREATE POLICY "itlg_uploads_delete_all"
    ON storage.objects FOR DELETE
    USING (bucket_id = 'itlg-uploads');
