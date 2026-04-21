-- RentFlow initial schema
-- Run once in Supabase SQL Editor (Dashboard → SQL editor → New query).
-- All tables are created first; policies are added at the end after every
-- referenced table exists (PostgreSQL validates cross-table references in
-- policy USING/CHECK expressions at creation time).

-- =========================================================================
-- TABLES
-- =========================================================================

-- profiles (1:1 with auth.users) -------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  display_name text        not null default '',
  role         text        not null default 'owner'
                 check (role in ('owner', 'renter')),
  phone        text,
  email        text,
  created_at   timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- properties (owner portfolio) -----------------------------------------------
create table if not exists public.properties (
  id         uuid        primary key default gen_random_uuid(),
  owner_id   uuid        not null references public.profiles (id) on delete cascade,
  name       text        not null,
  location   text,
  units_total int        not null default 1,
  base_rent  numeric     not null default 0,
  address    text,
  created_at timestamptz not null default now()
);

alter table public.properties enable row level security;

-- tenants (assigned to a property; optional renter link) ---------------------
create table if not exists public.tenants (
  id                uuid        primary key default gen_random_uuid(),
  property_id       uuid        not null references public.properties (id) on delete cascade,
  owner_id          uuid        not null references public.profiles (id) on delete cascade,
  renter_profile_id uuid        references public.profiles (id) on delete set null,
  name              text        not null,
  unit              text        not null default '',
  phone             text,
  email             text,
  monthly_rent      numeric     not null default 0,
  payment_status    text        not null default 'due'
                      check (payment_status in ('paid', 'due', 'overdue')),
  move_in_date      date,
  created_at        timestamptz not null default now()
);

create index if not exists tenants_property_id_idx       on public.tenants (property_id);
create index if not exists tenants_owner_id_idx          on public.tenants (owner_id);
create index if not exists tenants_renter_profile_id_idx on public.tenants (renter_profile_id);

alter table public.tenants enable row level security;

-- bills -----------------------------------------------------------------------
create table if not exists public.bills (
  id          uuid        primary key default gen_random_uuid(),
  owner_id    uuid        not null references public.profiles   (id) on delete cascade,
  tenant_id   uuid        not null references public.tenants    (id) on delete cascade,
  property_id uuid        not null references public.properties (id) on delete cascade,
  bill_number text        not null,
  amount      numeric     not null,
  due_date    date        not null,
  status      text        not null default 'pending'
                check (status in ('pending', 'paid', 'overdue', 'cancelled')),
  notes       text,
  line_items  jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists bills_owner_id_idx  on public.bills (owner_id);
create index if not exists bills_tenant_id_idx on public.bills (tenant_id);

alter table public.bills enable row level security;

-- payments --------------------------------------------------------------------
create table if not exists public.payments (
  id              uuid        primary key default gen_random_uuid(),
  bill_id         uuid        not null references public.bills    (id) on delete cascade,
  owner_id        uuid        not null references public.profiles  (id) on delete cascade,
  tenant_id       uuid        not null references public.tenants   (id) on delete cascade,
  amount          numeric     not null,
  paid_at         timestamptz,
  method          text,
  transaction_ref text,
  status          text        not null default 'pending'
                    check (status in ('pending', 'paid', 'failed', 'overdue', 'cancelled')),
  created_at      timestamptz not null default now()
);

create index if not exists payments_bill_id_idx  on public.payments (bill_id);
create index if not exists payments_owner_id_idx on public.payments (owner_id);

alter table public.payments enable row level security;

-- =========================================================================
-- AUTO-CREATE PROFILE TRIGGER (runs on auth.users INSERT)
-- =========================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, role, phone, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'owner'),
    nullif(new.raw_user_meta_data->>'phone', ''),
    new.email
  )
  on conflict (id) do update set
    display_name = excluded.display_name,
    role         = excluded.role,
    phone        = coalesce(excluded.phone,  public.profiles.phone),
    email        = coalesce(excluded.email,  public.profiles.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =========================================================================
-- RLS POLICIES
-- (All four tables exist by this point, so cross-table references are safe.)
-- =========================================================================

-- profiles -------------------------------------------------------------------
-- Self-read, landlord-read (any owner whose tenant row links this renter),
-- and self-update / self-insert.
create policy "profiles_select_self_or_landlord"
  on public.profiles for select
  using (
    auth.uid() = id
    or exists (
      select 1 from public.tenants t
      where t.renter_profile_id = auth.uid()
        and t.owner_id = profiles.id
    )
  );

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

-- properties -----------------------------------------------------------------
create policy "properties_owner_all"
  on public.properties for all
  using     (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- tenants --------------------------------------------------------------------
create policy "tenants_select_owner_or_renter"
  on public.tenants for select
  using (auth.uid() = owner_id or auth.uid() = renter_profile_id);

create policy "tenants_insert_owner"
  on public.tenants for insert
  with check (auth.uid() = owner_id);

create policy "tenants_update_owner"
  on public.tenants for update
  using     (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

create policy "tenants_delete_owner"
  on public.tenants for delete
  using (auth.uid() = owner_id);

-- bills ----------------------------------------------------------------------
create policy "bills_select_owner_or_renter"
  on public.bills for select
  using (
    auth.uid() = owner_id
    or exists (
      select 1 from public.tenants t
      where t.id = bills.tenant_id
        and t.renter_profile_id = auth.uid()
    )
  );

create policy "bills_insert_owner"
  on public.bills for insert
  with check (auth.uid() = owner_id);

create policy "bills_update_owner"
  on public.bills for update
  using     (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Linked renter can mark a bill paid (e.g. after recording payment).
create policy "bills_update_linked_renter"
  on public.bills for update
  using (
    exists (
      select 1 from public.tenants t
      where t.id = bills.tenant_id
        and t.renter_profile_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.tenants t
      where t.id = bills.tenant_id
        and t.renter_profile_id = auth.uid()
    )
  );

create policy "bills_delete_owner"
  on public.bills for delete
  using (auth.uid() = owner_id);

-- payments -------------------------------------------------------------------
create policy "payments_select_owner_or_renter"
  on public.payments for select
  using (
    auth.uid() = owner_id
    or exists (
      select 1 from public.tenants t
      where t.id = payments.tenant_id
        and t.renter_profile_id = auth.uid()
    )
  );

create policy "payments_insert_owner"
  on public.payments for insert
  with check (auth.uid() = owner_id);

create policy "payments_update_owner"
  on public.payments for update
  using     (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Linked renter can update their own pending payment row.
create policy "payments_update_linked_renter"
  on public.payments for update
  using (
    exists (
      select 1 from public.tenants t
      where t.id = payments.tenant_id
        and t.renter_profile_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.tenants t
      where t.id = payments.tenant_id
        and t.renter_profile_id = auth.uid()
    )
  );

create policy "payments_delete_owner"
  on public.payments for delete
  using (auth.uid() = owner_id);
