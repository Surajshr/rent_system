-- Storage policies for RentFlow QR images (bucket `qr_codes`, prefix `payment_qr/`).
-- Apply in SQL Editor after verifying bucket id matches Dashboard → Storage → bucket name.
--
-- Why your dashboard list was empty:
-- • Policies requiring auth.role() = 'anon' block logged-in Flutter users (authenticated JWT).
-- • Requiring folder `public/` blocks paths under `payment_qr/`.
-- • extension = 'jpg' only excludes .png/.jpeg/etc.
--
-- Drop old conflicting policies first (names from Dashboard → Storage → Policies), e.g.:
--   DROP POLICY IF EXISTS "<your_old_policy_name>" ON storage.objects;

-- Read (LIST + GET + signed URLs) for signed-in app users -----------------------------
create policy "qr_codes_select_authenticated_payment_qr"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'qr_codes'
    and (
      name like 'payment_qr/%'
      or name = 'payment_qr'
    )
    and coalesce(lower(storage.extension(name)), '') in (
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'
    )
  );

-- Optional: allow anonymous read of the same paths (e.g. embed without login).
-- Uncomment if you need `anon` access; otherwise omit to keep bucket private to auth users.
-- create policy "qr_codes_select_anon_payment_qr"
--   on storage.objects
--   for select
--   to anon
--   using (
--     bucket_id = 'qr_codes'
--     and (name like 'payment_qr/%' or name = 'payment_qr')
--     and coalesce(lower(storage.extension(name)), '') in (
--       'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'
--     )
--   );
