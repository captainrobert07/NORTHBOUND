-- NORTHBOUND Shared Trip · run in your own Supabase SQL editor.
-- Public anon key is used in browser; NEVER store service_role keys there.
create extension if not exists pgcrypto;
create table if not exists public.trip_groups (
 id uuid primary key default gen_random_uuid(),
 name text not null check(char_length(name) between 1 and 100),
 invite_code uuid unique not null default gen_random_uuid(),
 owner_id uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table if not exists public.trip_members (
 group_id uuid not null references public.trip_groups(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 display_name text check(char_length(display_name)<=80),
 joined_at timestamptz not null default now(),
 primary key(group_id,user_id)
);
create table if not exists public.trip_documents (
 group_id uuid not null references public.trip_groups(id) on delete cascade,
 key text not null check(char_length(key)<=90),
 payload jsonb not null,
 updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now(),
 primary key(group_id,key)
);
create table if not exists public.trip_expenses (
 group_id uuid not null references public.trip_groups(id) on delete cascade,
 id text not null check(char_length(id)<=150),
 payload jsonb not null,
 updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now(),
 primary key(group_id,id)
);
create table if not exists public.trip_journal_entries (
 group_id uuid not null references public.trip_groups(id) on delete cascade,
 id text not null check(char_length(id)<=150),
 entry_date date not null,
 title text not null check(char_length(title) between 1 and 160),
 body text not null default '',
 mood text not null default '🙂 Good' check(char_length(mood)<=60),
 updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now(),
 primary key(group_id,id)
);
create table if not exists public.trip_payments (
 group_id uuid not null references public.trip_groups(id) on delete cascade,
 id text not null check(char_length(id)<=150),
 payment_date date not null,
 paid_by text not null check(char_length(paid_by) between 1 and 80),
 received_by text not null check(char_length(received_by) between 1 and 80),
 amount numeric(12,2) not null check(amount>0),
 method text not null default 'UPI' check(char_length(method)<=40),
 updated_by uuid references auth.users(id),
 updated_at timestamptz not null default now(),
 primary key(group_id,id),
 check(paid_by<>received_by)
);
create or replace function public.is_trip_member(p_group uuid) returns boolean
language sql stable security definer set search_path=public as $$
 select auth.uid() is not null and exists(select 1 from public.trip_members m where m.group_id=p_group and m.user_id=auth.uid());
$$;
revoke all on function public.is_trip_member(uuid) from public;
grant execute on function public.is_trip_member(uuid) to authenticated;
-- SECURITY DEFINER functions are owned by project administrator and bypass RLS to insert initial membership.
create or replace function public.create_northbound_group(p_name text) returns uuid
language plpgsql security definer set search_path=public as $$
declare gid uuid;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if p_name is null or char_length(btrim(p_name)) not between 1 and 100 then raise exception 'Invalid group name'; end if;
 insert into public.trip_groups(name,owner_id) values (btrim(p_name),auth.uid()) returning id into gid;
 insert into public.trip_members(group_id,user_id,display_name) values(gid,auth.uid(),'Owner');
 return gid;
end;$$;
create or replace function public.join_northbound_group(p_invite uuid,p_display_name text default 'Traveller') returns uuid
language plpgsql security definer set search_path=public as $$
declare gid uuid;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 select id into gid from public.trip_groups where invite_code=p_invite;
 if gid is null then raise exception 'Invite code not found'; end if;
 insert into public.trip_members(group_id,user_id,display_name) values(gid,auth.uid(),left(coalesce(nullif(btrim(p_display_name),''),'Traveller'),80)) on conflict (group_id,user_id) do nothing;
 return gid;
end;$$;
revoke all on function public.create_northbound_group(text) from public;
revoke all on function public.join_northbound_group(uuid,text) from public;
grant execute on function public.create_northbound_group(text) to authenticated;
grant execute on function public.join_northbound_group(uuid,text) to authenticated;
alter table public.trip_groups enable row level security;
alter table public.trip_members enable row level security;
alter table public.trip_documents enable row level security;
alter table public.trip_expenses enable row level security;
alter table public.trip_journal_entries enable row level security;
alter table public.trip_payments enable row level security;
drop policy if exists read_groups on public.trip_groups;
create policy read_groups on public.trip_groups for select to authenticated using(public.is_trip_member(id));
drop policy if exists read_members on public.trip_members;
create policy read_members on public.trip_members for select to authenticated using(public.is_trip_member(group_id));
drop policy if exists read_docs on public.trip_documents;
create policy read_docs on public.trip_documents for select to authenticated using(public.is_trip_member(group_id));
drop policy if exists insert_docs on public.trip_documents;
create policy insert_docs on public.trip_documents for insert to authenticated with check(public.is_trip_member(group_id) and updated_by=auth.uid());
drop policy if exists update_docs on public.trip_documents;
create policy update_docs on public.trip_documents for update to authenticated using(public.is_trip_member(group_id)) with check(public.is_trip_member(group_id) and updated_by=auth.uid());
drop policy if exists delete_docs on public.trip_documents;
create policy delete_docs on public.trip_documents for delete to authenticated using(public.is_trip_member(group_id));
drop policy if exists read_expenses on public.trip_expenses;
create policy read_expenses on public.trip_expenses for select to authenticated using(public.is_trip_member(group_id));
drop policy if exists insert_expenses on public.trip_expenses;
create policy insert_expenses on public.trip_expenses for insert to authenticated with check(public.is_trip_member(group_id) and updated_by=auth.uid());
drop policy if exists update_expenses on public.trip_expenses;
create policy update_expenses on public.trip_expenses for update to authenticated using(public.is_trip_member(group_id)) with check(public.is_trip_member(group_id) and updated_by=auth.uid());
drop policy if exists delete_expenses on public.trip_expenses;
create policy delete_expenses on public.trip_expenses for delete to authenticated using(public.is_trip_member(group_id));
drop policy if exists read_journal_entries on public.trip_journal_entries;
create policy read_journal_entries on public.trip_journal_entries for select to authenticated using(public.is_trip_member(group_id));
drop policy if exists write_journal_entries on public.trip_journal_entries;
create policy write_journal_entries on public.trip_journal_entries for all to authenticated using(public.is_trip_member(group_id)) with check(public.is_trip_member(group_id) and updated_by=auth.uid());
drop policy if exists read_payments on public.trip_payments;
create policy read_payments on public.trip_payments for select to authenticated using(public.is_trip_member(group_id));
drop policy if exists write_payments on public.trip_payments;
create policy write_payments on public.trip_payments for all to authenticated using(public.is_trip_member(group_id)) with check(public.is_trip_member(group_id) and updated_by=auth.uid());
-- Supabase Realtime: changes become visible to authenticated group members under RLS.
do $$ begin
 if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='trip_documents') then
   alter publication supabase_realtime add table public.trip_documents;
 end if;
 if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='trip_expenses') then
   alter publication supabase_realtime add table public.trip_expenses;
 end if;
 if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='trip_journal_entries') then
   alter publication supabase_realtime add table public.trip_journal_entries;
 end if;
 if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='trip_payments') then
   alter publication supabase_realtime add table public.trip_payments;
 end if;
end $$;
-- Files are intentionally local-only. For cloud file sharing add a PRIVATE bucket and separate storage RLS policies after security review.
