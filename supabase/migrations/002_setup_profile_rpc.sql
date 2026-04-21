-- RentFlow migration 002
-- Adds a security-definer RPC that safely upserts a user's own profile,
-- bypassing INSERT RLS.  p_user_id is passed explicitly because auth.uid()
-- can be null immediately after signup before the JWT is fully propagated.
-- Security is enforced: if auth.uid() IS available it MUST match p_user_id.
-- Run in Supabase SQL Editor after 001_rentflow_schema.sql.

-- Drop ALL overloads so CREATE OR REPLACE can succeed unambiguously.
drop function if exists public.setup_my_profile(text, text, text, text);
drop function if exists public.setup_my_profile(uuid, text, text, text, text);

create or replace function public.setup_my_profile(
  p_user_id      uuid,
  p_display_name text,
  p_role         text,
  p_phone        text,
  p_email        text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- If auth.uid() is resolvable, enforce that the caller owns this profile.
  if auth.uid() is not null and auth.uid() is distinct from p_user_id then
    raise exception 'unauthorized: you can only manage your own profile';
  end if;

  insert into public.profiles (id, display_name, role, phone, email)
  values (
    p_user_id,
    p_display_name,
    p_role,
    nullif(trim(p_phone), ''),
    nullif(trim(p_email), '')
  )
  on conflict (id) do update set
    display_name = case
                     when excluded.display_name <> ''
                     then excluded.display_name
                     else profiles.display_name
                   end,
    role  = excluded.role,
    phone = coalesce(excluded.phone,  profiles.phone),
    email = coalesce(excluded.email,  profiles.email);
end;
$$;

-- Restrict to authenticated users only.
revoke execute on function public.setup_my_profile from anon;
grant  execute on function public.setup_my_profile to authenticated;
