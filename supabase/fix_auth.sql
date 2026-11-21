-- =============================================================================
-- SKRIP PERBAIKAN SUPABASE AUTH (Jalankan di Supabase SQL Editor)
-- =============================================================================
-- Skrip ini melengkapi kolom-kolom wajib GoTrue di auth.users dan auth.identities
-- agar proses login dengan password123 berjalan 100% mulus tanpa error 500.
-- =============================================================================

-- 1. Perbaiki kolom teks di auth.users agar tidak NULL (mencegah GoTrue scan error)
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

-- 2. Pastikan entri identitas akun di auth.identities tersedia
INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
) VALUES 
(
    'a1111111-1111-1111-1111-111111111111',
    'a1111111-1111-1111-1111-111111111111',
    format('{"sub":"%s","email":"%s"}', 'a1111111-1111-1111-1111-111111111111', 'andre@students.usu.ac.id')::jsonb,
    'email',
    'a1111111-1111-1111-1111-111111111111',
    NOW(), NOW(), NOW()
),
(
    'b2222222-2222-2222-2222-222222222222',
    'b2222222-2222-2222-2222-222222222222',
    format('{"sub":"%s","email":"%s"}', 'b2222222-2222-2222-2222-222222222222', 'abbil@itlg.usu.ac.id')::jsonb,
    'email',
    'b2222222-2222-2222-2222-222222222222',
    NOW(), NOW(), NOW()
),
(
    'c3333333-3333-3333-3333-333333333333',
    'c3333333-3333-3333-3333-333333333333',
    format('{"sub":"%s","email":"%s"}', 'c3333333-3333-3333-3333-333333333333', 'reagan@itlg.usu.ac.id')::jsonb,
    'email',
    'c3333333-3333-3333-3333-333333333333',
    NOW(), NOW(), NOW()
),
(
    'd4444444-4444-4444-4444-444444444444',
    'd4444444-4444-4444-4444-444444444444',
    format('{"sub":"%s","email":"%s"}', 'd4444444-4444-4444-4444-444444444444', 'daniele@usu.ac.id')::jsonb,
    'email',
    'd4444444-4444-4444-4444-444444444444',
    NOW(), NOW(), NOW()
)
ON CONFLICT (provider, provider_id) DO NOTHING;
