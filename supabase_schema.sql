-- JurisFlow: esquema inicial para Supabase/PostgreSQL
-- IMPORTANTE: executar em projeto de desenvolvimento e revisar com profissional de segurança.
-- Não representa certificação LGPD nem substitui teste de autorização.
create extension if not exists pgcrypto;

create table if not exists public.offices (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.office_members (
  office_id uuid not null references public.offices(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','admin','member')),
  created_at timestamptz not null default now(),
  primary key (office_id,user_id)
);
create or replace function public.is_office_member(target_office uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.office_members m where m.office_id=target_office and m.user_id=auth.uid()) $$;
create or replace function public.is_office_admin(target_office uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.office_members m where m.office_id=target_office and m.user_id=auth.uid() and m.role in ('owner','admin')) $$;

create table if not exists public.clients (
 id uuid primary key default gen_random_uuid(), office_id uuid not null references public.offices(id) on delete cascade,
 name text not null, document_ref text, phone text, email text, client_type text, notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.legal_cases (
 id uuid primary key default gen_random_uuid(), office_id uuid not null references public.offices(id) on delete cascade,
 client_id uuid references public.clients(id) on delete set null, case_number text, title text not null,
 legal_area text, status text not null default 'Em andamento', next_deadline date, notes text,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.deadlines (
 id uuid primary key default gen_random_uuid(), office_id uuid not null references public.offices(id) on delete cascade,
 case_id uuid references public.legal_cases(id) on delete set null, title text not null, due_at timestamptz not null,
 kind text not null default 'Prazo', status text not null default 'Pendente', notes text,
 created_at timestamptz not null default now()
);
create table if not exists public.tasks (
 id uuid primary key default gen_random_uuid(), office_id uuid not null references public.offices(id) on delete cascade,
 case_id uuid references public.legal_cases(id) on delete set null, title text not null, assigned_to uuid references auth.users(id) on delete set null,
 due_date date, priority text not null default 'Normal', status text not null default 'Pendente',
 created_at timestamptz not null default now()
);
create table if not exists public.financial_entries (
 id uuid primary key default gen_random_uuid(), office_id uuid not null references public.offices(id) on delete cascade,
 client_id uuid references public.clients(id) on delete set null, description text not null,
 entry_type text not null check (entry_type in ('Recebimento','Despesa')), amount numeric(12,2) not null check (amount>=0),
 due_date date, status text not null default 'Pendente', paid_at date, created_at timestamptz not null default now()
);
create table if not exists public.document_records (
 id uuid primary key default gen_random_uuid(), office_id uuid not null references public.offices(id) on delete cascade,
 case_id uuid references public.legal_cases(id) on delete set null, name text not null, document_type text,
 storage_path text, notes text, created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now()
);
create table if not exists public.client_updates (
 id uuid primary key default gen_random_uuid(), office_id uuid not null references public.offices(id) on delete cascade,
 case_id uuid references public.legal_cases(id) on delete cascade, client_id uuid references public.clients(id) on delete cascade,
 title text not null, message text not null, visible_to_client boolean not null default false,
 created_at timestamptz not null default now()
);

-- Enable RLS on all tenant-scoped tables.
alter table public.offices enable row level security;
alter table public.office_members enable row level security;
alter table public.clients enable row level security;
alter table public.legal_cases enable row level security;
alter table public.deadlines enable row level security;
alter table public.tasks enable row level security;
alter table public.financial_entries enable row level security;
alter table public.document_records enable row level security;
alter table public.client_updates enable row level security;

drop policy if exists "members read own office" on public.offices;
create policy "members read own office" on public.offices for select to authenticated using (public.is_office_member(id));
drop policy if exists "members read membership" on public.office_members;
create policy "members read membership" on public.office_members for select to authenticated using (public.is_office_member(office_id));
-- Membership management is intentionally not opened to client-side inserts/updates.
do $$ declare t text; begin
 foreach t in array array['clients','legal_cases','deadlines','tasks','financial_entries','document_records','client_updates'] loop
  execute format('drop policy if exists "office members read %1$s" on public.%1$I',t);
  execute format('create policy "office members read %1$s" on public.%1$I for select to authenticated using (public.is_office_member(office_id))',t);
  execute format('drop policy if exists "office members insert %1$s" on public.%1$I',t);
  execute format('create policy "office members insert %1$s" on public.%1$I for insert to authenticated with check (public.is_office_member(office_id))',t);
  execute format('drop policy if exists "office members update %1$s" on public.%1$I',t);
  execute format('create policy "office members update %1$s" on public.%1$I for update to authenticated using (public.is_office_member(office_id)) with check (public.is_office_member(office_id))',t);
  execute format('drop policy if exists "office admins delete %1$s" on public.%1$I',t);
  execute format('create policy "office admins delete %1$s" on public.%1$I for delete to authenticated using (public.is_office_admin(office_id))',t);
 end loop;
end $$;

-- TODO antes de produção:
-- 1) criar fluxo seguro de onboarding: criar escritório e owner via Edge Function/servidor,
--    nunca permitir que o browser escolha arbitrariamente office_id para se apropriar de tenant.
-- 2) validar referências client_id/case_id pertencentes ao mesmo office_id.
-- 3) configurar Storage privado + policies para documentos.
-- 4) implementar portal externo com tokens de curta duração e escopo mínimo, sem abrir tabelas ao público.
-- 5) configurar logs, backups, retenção, exportação/exclusão e política de privacidade.
-- 6) alertas de prazo em backend/cron e integração com calendário/tribunais só após validação.
-- 7) Nunca expor service_role key no front-end.
