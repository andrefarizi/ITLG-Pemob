-- =============================================================================
-- PEMBARUAN EMAIL RESMI USU UNTUK 4 ROLE (ITLG MOBILE)
-- Jalankan di Supabase Dashboard -> SQL Editor -> Run
-- =============================================================================

-- 1. Praktikan: Andre Al Farizi Sebayang -> andreal@students.usu.ac.id
UPDATE public.profiles
SET email = 'andreal@students.usu.ac.id', updated_at = NOW()
WHERE id = 'a1111111-1111-1111-1111-111111111111';

UPDATE auth.users
SET email = 'andreal@students.usu.ac.id', updated_at = NOW()
WHERE id = 'a1111111-1111-1111-1111-111111111111';

UPDATE auth.identities
SET identity_data = jsonb_set(identity_data, '{email}', '"andreal@students.usu.ac.id"'), updated_at = NOW()
WHERE user_id = 'a1111111-1111-1111-1111-111111111111';

-- 2. Aslab: Abbil Rizki -> abbilrizki@students.usu.ac.id
UPDATE public.profiles
SET email = 'abbilrizki@students.usu.ac.id', updated_at = NOW()
WHERE id = 'b2222222-2222-2222-2222-222222222222';

UPDATE auth.users
SET email = 'abbilrizki@students.usu.ac.id', updated_at = NOW()
WHERE id = 'b2222222-2222-2222-2222-222222222222';

UPDATE auth.identities
SET identity_data = jsonb_set(identity_data, '{email}', '"abbilrizki@students.usu.ac.id"'), updated_at = NOW()
WHERE user_id = 'b2222222-2222-2222-2222-222222222222';

-- 3. Laboran: Reagan Brian -> reaganbrian@students.usu.ac.id
UPDATE public.profiles
SET email = 'reaganbrian@students.usu.ac.id', updated_at = NOW()
WHERE id = 'c3333333-3333-3333-3333-333333333333';

UPDATE auth.users
SET email = 'reaganbrian@students.usu.ac.id', updated_at = NOW()
WHERE id = 'c3333333-3333-3333-3333-333333333333';

UPDATE auth.identities
SET identity_data = jsonb_set(identity_data, '{email}', '"reaganbrian@students.usu.ac.id"'), updated_at = NOW()
WHERE user_id = 'c3333333-3333-3333-3333-333333333333';

-- 4. Dosen: Dr. Eng. Daniele Christian, M.Kom. -> danielechristian@students.usu.ac.id
UPDATE public.profiles
SET email = 'danielechristian@students.usu.ac.id', updated_at = NOW()
WHERE id = 'd4444444-4444-4444-4444-444444444444';

UPDATE auth.users
SET email = 'danielechristian@students.usu.ac.id', updated_at = NOW()
WHERE id = 'd4444444-4444-4444-4444-444444444444';

UPDATE auth.identities
SET identity_data = jsonb_set(identity_data, '{email}', '"danielechristian@students.usu.ac.id"'), updated_at = NOW()
WHERE user_id = 'd4444444-4444-4444-4444-444444444444';

SELECT id, identifier, full_name, email, role FROM public.profiles ORDER BY role;
