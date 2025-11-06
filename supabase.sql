-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.bank_accounts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  bank_name text NOT NULL,
  account_number text NOT NULL,
  account_holder text,
  is_public boolean NOT NULL DEFAULT false,
  memo text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT bank_accounts_pkey PRIMARY KEY (id),
  CONSTRAINT bank_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);

-- bank_accounts triggers ------------------------------------------------------
drop trigger if exists set_bank_account_holder on public.bank_accounts;
drop function if exists public.set_bank_account_holder();
create function public.set_bank_account_holder()
  returns trigger
  language plpgsql
as $$
begin
  if new.account_holder is null or btrim(new.account_holder) = '' then
    select name into new.account_holder
    from public.users
    where id = new.user_id;
  end if;

  return new;
end;
$$;

create trigger set_bank_account_holder
  before insert on public.bank_accounts
  for each row
  execute function public.set_bank_account_holder();

CREATE TABLE public.exchange_rates (
  currency text NOT NULL,
  rate numeric NOT NULL CHECK (rate > 0::numeric),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  base_currency text NOT NULL DEFAULT 'KRW'::text,
  rate_date date NOT NULL DEFAULT CURRENT_DATE,
  CONSTRAINT exchange_rates_pkey PRIMARY KEY (base_currency, currency, rate_date)
);
CREATE TABLE public.expenses (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL,
  payer_id uuid NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0::numeric),
  description text,
  expense_date date NOT NULL DEFAULT CURRENT_DATE,
  participants jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_by uuid NOT NULL,
  currency text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT expenses_pkey PRIMARY KEY (id),
  CONSTRAINT expenses_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id),
  CONSTRAINT expenses_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id),
  CONSTRAINT expenses_payer_id_fkey FOREIGN KEY (payer_id) REFERENCES public.users(id)
);
CREATE TABLE public.groups (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  invite_code text NOT NULL DEFAULT encode(gen_random_bytes(6), 'hex'::text) UNIQUE,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  owner_id uuid NOT NULL,
  base_currency text NOT NULL DEFAULT 'KRW'::text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT groups_pkey PRIMARY KEY (id),
  CONSTRAINT groups_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id)
);
CREATE TABLE public.members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  group_id uuid NOT NULL,
  joined_at timestamp with time zone NOT NULL DEFAULT now(),
  role USER-DEFINED NOT NULL DEFAULT 'member'::membership_role,
  CONSTRAINT members_pkey PRIMARY KEY (id),
  CONSTRAINT members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id)
);
CREATE TABLE public.settlements (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL,
  from_user uuid NOT NULL,
  to_user uuid NOT NULL,
  amount numeric NOT NULL CHECK (amount > 0::numeric),
  currency text NOT NULL,
  status USER-DEFINED NOT NULL,
  memo text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT settlements_pkey PRIMARY KEY (id),
  CONSTRAINT settlements_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id),
  CONSTRAINT settlements_from_user_fkey FOREIGN KEY (from_user) REFERENCES public.users(id),
  CONSTRAINT settlements_to_user_fkey FOREIGN KEY (to_user) REFERENCES public.users(id)
);
CREATE TABLE public.users (
  id uuid NOT NULL,
  email text NOT NULL UNIQUE,
  name text,
  provider text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  avatar_url text,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
