-- =====================================================================
-- AttendX — Supabase Schema
-- Run this entire file in the Supabase SQL Editor (or via `supabase db push`)
-- =====================================================================

-- Extensions
create extension if not exists "uuid-ossp";

-- =====================================================================
-- TABLE: profiles
-- =====================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  email text not null,
  college text,
  semester text,
  section text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_email on public.profiles (email);

-- =====================================================================
-- TABLE: subjects
-- =====================================================================
create table if not exists public.subjects (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_name text not null,
  subject_code text,
  faculty_name text,
  credits integer default 0,
  target_percentage numeric(5, 2) not null default 75.00,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_subjects_user_id on public.subjects (user_id);

-- =====================================================================
-- TABLE: attendance_records
-- =====================================================================
create table if not exists public.attendance_records (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id uuid not null references public.subjects (id) on delete cascade,
  class_date date not null,
  class_number integer not null default 1,
  status text not null check (status in ('present', 'absent')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_attendance_unique unique (user_id, subject_id, class_date, class_number)
);

create index if not exists idx_attendance_user_id on public.attendance_records (user_id);
create index if not exists idx_attendance_subject_id on public.attendance_records (subject_id);
create index if not exists idx_attendance_class_date on public.attendance_records (class_date);
create index if not exists idx_attendance_user_subject on public.attendance_records (user_id, subject_id);

-- =====================================================================
-- TABLE: timetable
-- =====================================================================
create table if not exists public.timetable (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users (id) on delete cascade,
  subject_id uuid not null references public.subjects (id) on delete cascade,
  day_of_week integer not null check (day_of_week between 1 and 7), -- 1 = Monday ... 7 = Sunday
  start_time time not null,
  end_time time not null,
  room text,
  created_at timestamptz not null default now()
);

create index if not exists idx_timetable_user_id on public.timetable (user_id);
create index if not exists idx_timetable_day on public.timetable (user_id, day_of_week);

-- =====================================================================
-- TABLE: user_settings
-- =====================================================================
create table if not exists public.user_settings (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  theme text not null default 'system' check (theme in ('light', 'dark', 'system')),
  default_target_percentage numeric(5, 2) not null default 75.00,
  notifications_enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_user_settings_user_id on public.user_settings (user_id);

-- =====================================================================
-- updated_at auto-touch trigger
-- =====================================================================
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
  before update on public.profiles
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_subjects_updated_at on public.subjects;
create trigger trg_subjects_updated_at
  before update on public.subjects
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_attendance_updated_at on public.attendance_records;
create trigger trg_attendance_updated_at
  before update on public.attendance_records
  for each row execute function public.touch_updated_at();

drop trigger if exists trg_settings_updated_at on public.user_settings;
create trigger trg_settings_updated_at
  before update on public.user_settings
  for each row execute function public.touch_updated_at();

-- =====================================================================
-- Auto-create profile + settings row on new auth user
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email
  )
  on conflict (id) do nothing;

  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists trg_on_auth_user_created on auth.users;
create trigger trg_on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles enable row level security;
alter table public.subjects enable row level security;
alter table public.attendance_records enable row level security;
alter table public.timetable enable row level security;
alter table public.user_settings enable row level security;

-- profiles: user can only read/update their own row
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);

-- subjects
drop policy if exists "subjects_select_own" on public.subjects;
create policy "subjects_select_own" on public.subjects
  for select using (auth.uid() = user_id);

drop policy if exists "subjects_insert_own" on public.subjects;
create policy "subjects_insert_own" on public.subjects
  for insert with check (auth.uid() = user_id);

drop policy if exists "subjects_update_own" on public.subjects;
create policy "subjects_update_own" on public.subjects
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "subjects_delete_own" on public.subjects;
create policy "subjects_delete_own" on public.subjects
  for delete using (auth.uid() = user_id);

-- attendance_records
drop policy if exists "attendance_select_own" on public.attendance_records;
create policy "attendance_select_own" on public.attendance_records
  for select using (auth.uid() = user_id);

drop policy if exists "attendance_insert_own" on public.attendance_records;
create policy "attendance_insert_own" on public.attendance_records
  for insert with check (auth.uid() = user_id);

drop policy if exists "attendance_update_own" on public.attendance_records;
create policy "attendance_update_own" on public.attendance_records
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "attendance_delete_own" on public.attendance_records;
create policy "attendance_delete_own" on public.attendance_records
  for delete using (auth.uid() = user_id);

-- timetable
drop policy if exists "timetable_select_own" on public.timetable;
create policy "timetable_select_own" on public.timetable
  for select using (auth.uid() = user_id);

drop policy if exists "timetable_insert_own" on public.timetable;
create policy "timetable_insert_own" on public.timetable
  for insert with check (auth.uid() = user_id);

drop policy if exists "timetable_update_own" on public.timetable;
create policy "timetable_update_own" on public.timetable
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "timetable_delete_own" on public.timetable;
create policy "timetable_delete_own" on public.timetable
  for delete using (auth.uid() = user_id);

-- user_settings
drop policy if exists "settings_select_own" on public.user_settings;
create policy "settings_select_own" on public.user_settings
  for select using (auth.uid() = user_id);

drop policy if exists "settings_insert_own" on public.user_settings;
create policy "settings_insert_own" on public.user_settings
  for insert with check (auth.uid() = user_id);

drop policy if exists "settings_update_own" on public.user_settings;
create policy "settings_update_own" on public.user_settings
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- =====================================================================
-- REALTIME
-- =====================================================================
alter publication supabase_realtime add table public.attendance_records;
alter publication supabase_realtime add table public.subjects;
alter publication supabase_realtime add table public.timetable;

-- =====================================================================
-- End of schema
-- =====================================================================
