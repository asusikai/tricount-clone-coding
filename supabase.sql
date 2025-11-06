-- Supabase schema definition for splitBills
-- Execute this script from the Supabase SQL Editor.

-- Required extensions ---------------------------------------------------------
create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- Enumerations ----------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_type where typname = 'membership_role') then
    create type public.membership_role as enum ('owner', 'member');
  end if;

  if not exists (select 1 from pg_type where typname = 'settlement_status') then
    create type public.settlement_status as enum ('pending', 'paid', 'rejected', 'rolled_back');
  end if;
end $$;

-- Tables ----------------------------------------------------------------------

create table if not exists public.users (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique,
  name text,
  nickname text,
  provider text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.groups (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.users (id) on delete cascade,
  name text not null,
  base_currency text not null default 'KRW',
  invite_code text not null unique default encode(gen_random_bytes(6), 'hex'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.users (id) on delete cascade,
  role public.membership_role not null default 'member',
  joined_at timestamptz not null default now(),
  unique (group_id, user_id)
);

create table if not exists public.bank_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users (id) on delete cascade,
  bank_name text not null,
  account_number text not null,
  account_holder text,
  is_public boolean not null default false,
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, account_number)
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  payer_id uuid not null references public.users (id) on delete cascade,
  created_by uuid not null references public.users (id) on delete cascade,
  amount numeric(14,2) not null check (amount > 0),
  currency text not null,
  description text,
  expense_date date not null default current_date,
  participants jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.settlements (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  from_user uuid not null references public.users (id) on delete cascade,
  to_user uuid not null references public.users (id) on delete cascade,
  amount numeric(14,2) not null check (amount > 0),
  currency text not null,
  status public.settlement_status not null default 'pending',
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.exchange_rates (
  base_currency text not null default 'KRW',
  currency text not null,
  rate numeric(18,8) not null check (rate > 0),
  rate_date date not null default current_date,
  updated_at timestamptz not null default now(),
  primary key (base_currency, currency, rate_date)
);

-- Row Level Security ----------------------------------------------------------
alter table public.users enable row level security;
alter table public.groups enable row level security;
alter table public.members enable row level security;
alter table public.bank_accounts enable row level security;
alter table public.expenses enable row level security;
alter table public.settlements enable row level security;
alter table public.exchange_rates enable row level security;

-- users policies --------------------------------------------------------------
drop policy if exists "Users select own profile" on public.users;
create policy "Users select own profile"
  on public.users for select
  using (id = auth.uid());

drop policy if exists "Users update own profile" on public.users;
create policy "Users update own profile"
  on public.users for update
  using (id = auth.uid())
  with check (id = auth.uid());

-- groups policies -------------------------------------------------------------
drop policy if exists "Members read groups" on public.groups;
create policy "Members read groups"
  on public.groups for select
  using (
    owner_id = auth.uid()
    or exists (
      select 1
      from public.members m
      where m.group_id = groups.id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "Users create groups" on public.groups;
create policy "Users create groups"
  on public.groups for insert
  with check (owner_id = auth.uid());

drop policy if exists "Owners manage groups" on public.groups;
create policy "Owners manage groups"
  on public.groups for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

drop policy if exists "Owners delete groups" on public.groups;
create policy "Owners delete groups"
  on public.groups for delete
  using (owner_id = auth.uid());

-- members policies ------------------------------------------------------------
drop policy if exists "Members read membership" on public.members;
create policy "Members read membership"
  on public.members for select
  using (
    exists (
      select 1
      from public.members m
      where m.group_id = members.group_id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "Users join groups" on public.members;
create policy "Users join groups"
  on public.members for insert
  with check (user_id = auth.uid());

drop policy if exists "Owners remove members" on public.members;
create policy "Owners remove members"
  on public.members for delete
  using (
    exists (
      select 1
      from public.members m
      where m.group_id = members.group_id
        and m.user_id = auth.uid()
        and m.role = 'owner'
    )
  );

-- bank_accounts policies ------------------------------------------------------
drop policy if exists "Users read bank accounts" on public.bank_accounts;
create policy "Users read bank accounts"
  on public.bank_accounts for select
  using (
    user_id = auth.uid()
    or is_public
  );

drop policy if exists "Users manage own bank accounts" on public.bank_accounts;
create policy "Users manage own bank accounts"
  on public.bank_accounts for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- expenses policies -----------------------------------------------------------
drop policy if exists "Members read expenses" on public.expenses;
create policy "Members read expenses"
  on public.expenses for select
  using (
    exists (
      select 1
      from public.members m
      where m.group_id = expenses.group_id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "Members create expenses" on public.expenses;
create policy "Members create expenses"
  on public.expenses for insert
  with check (
    created_by = auth.uid()
    and exists (
      select 1
      from public.members m
      where m.group_id = expenses.group_id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "Creators update expenses" on public.expenses;
create policy "Creators update expenses"
  on public.expenses for update
  using (created_by = auth.uid())
  with check (created_by = auth.uid());

drop policy if exists "Creators delete expenses" on public.expenses;
create policy "Creators delete expenses"
  on public.expenses for delete
  using (created_by = auth.uid());

-- settlements policies --------------------------------------------------------
drop policy if exists "Members read settlements" on public.settlements;
create policy "Members read settlements"
  on public.settlements for select
  using (
    exists (
      select 1
      from public.members m
      where m.group_id = settlements.group_id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "Members manage settlements" on public.settlements;
create policy "Members manage settlements"
  on public.settlements for insert
  with check (
    exists (
      select 1
      from public.members m
      where m.group_id = settlements.group_id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "Members update settlements" on public.settlements;
create policy "Members update settlements"
  on public.settlements for update
  using (
    exists (
      select 1
      from public.members m
      where m.group_id = settlements.group_id
        and m.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.members m
      where m.group_id = settlements.group_id
        and m.user_id = auth.uid()
    )
  );

drop policy if exists "Members delete settlements" on public.settlements;
create policy "Members delete settlements"
  on public.settlements for delete
  using (
    exists (
      select 1
      from public.members m
      where m.group_id = settlements.group_id
        and m.user_id = auth.uid()
    )
  );

-- exchange_rates policies -----------------------------------------------------
drop policy if exists "Authenticated read exchange rates" on public.exchange_rates;
create policy "Authenticated read exchange rates"
  on public.exchange_rates for select
  using (auth.role() = 'authenticated');

drop policy if exists "Service role manage exchange rates" on public.exchange_rates;
create policy "Service role manage exchange rates"
  on public.exchange_rates for all
  using (auth.role() = 'service_role')
  with check (auth.role() = 'service_role');
