-- RentFlow migration 003
-- Adds link_renter_to_tenant() RPC.
-- Run in Supabase SQL Editor after 002_setup_profile_rpc.sql.

drop function if exists public.link_renter_to_tenant(uuid, text);

create or replace function public.link_renter_to_tenant(
  p_tenant_id    uuid,
  p_renter_email text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $func$
declare
  v_owner_id    uuid;
  v_renter_id   uuid;
  v_renter_role text;
begin

  -- 1. Load the tenant's owner_id using := assignment (avoids SELECT INTO
  --    being misread as a plain-SQL table-creation statement by some editors).
  v_owner_id := (
    select owner_id
    from   public.tenants
    where  id = p_tenant_id
    limit  1
  );

  if v_owner_id is null then
    return jsonb_build_object('error', 'Tenant not found.');
  end if;

  if v_owner_id <> auth.uid() then
    return jsonb_build_object('error', 'You do not own this tenant record.');
  end if;

  -- 2. Look up renter by email (security definer bypasses profiles RLS).
  v_renter_id := (
    select id
    from   public.profiles
    where  lower(trim(email)) = lower(trim(p_renter_email))
    limit  1
  );

  v_renter_role := (
    select role
    from   public.profiles
    where  id = v_renter_id
    limit  1
  );

  if v_renter_id is null then
    return jsonb_build_object(
      'error',
      'No account found for "' || p_renter_email
        || '". Make sure the renter has signed up first.'
    );
  end if;

  -- 3. Must be a renter account.
  if v_renter_role <> 'renter' then
    return jsonb_build_object(
      'error', 'That account is registered as an owner, not a renter.'
    );
  end if;

  -- 4. Prevent linking a renter already linked to another unit.
  if exists (
    select 1
    from   public.tenants
    where  renter_profile_id = v_renter_id
      and  id <> p_tenant_id
  ) then
    return jsonb_build_object(
      'error',
      'This renter is already linked to another unit. '
      'Unlink them there first.'
    );
  end if;

  -- 5. Write the link.
  update public.tenants
  set    renter_profile_id = v_renter_id
  where  id = p_tenant_id;

  return jsonb_build_object('success', true, 'renter_id', v_renter_id::text);

end;
$func$;

revoke execute on function public.link_renter_to_tenant(uuid, text) from anon;
grant  execute on function public.link_renter_to_tenant(uuid, text) to authenticated;
