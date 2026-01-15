-- ============================================
-- SQUIBBLE DATABASE SCHEMA
-- Migration: 001_initial_schema
-- Date: 2024-12-27
-- Description: Initial database setup with tables, indexes, RLS policies
-- ============================================

-- 1. USERS TABLE (extends Supabase auth.users)
-- ============================================
create table if not exists public.users (
  id uuid references auth.users(id) on delete cascade primary key,
  display_name text not null,
  profile_image_url text,
  color_hex text not null default '#007AFF',
  is_premium boolean not null default false,
  streak int not null default 0,
  total_doodles_sent int not null default 0,
  device_token text,
  invite_code text unique not null,
  created_at timestamp with time zone default now()
);

-- 2. DOODLES TABLE
-- ============================================
create table if not exists public.doodles (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references public.users(id) on delete cascade not null,
  image_url text not null,
  created_at timestamp with time zone default now()
);

-- 3. DOODLE RECIPIENTS TABLE (junction table)
-- ============================================
create table if not exists public.doodle_recipients (
  id uuid primary key default gen_random_uuid(),
  doodle_id uuid references public.doodles(id) on delete cascade not null,
  recipient_id uuid references public.users(id) on delete cascade not null,
  viewed_at timestamp with time zone,
  created_at timestamp with time zone default now(),
  unique(doodle_id, recipient_id)
);

-- 4. FRIENDSHIPS TABLE
-- ============================================
create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid references public.users(id) on delete cascade not null,
  addressee_id uuid references public.users(id) on delete cascade not null,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamp with time zone default now(),
  unique(requester_id, addressee_id)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
create index if not exists idx_doodles_sender_id on public.doodles(sender_id);
create index if not exists idx_doodles_created_at on public.doodles(created_at desc);
create index if not exists idx_doodle_recipients_recipient_id on public.doodle_recipients(recipient_id);
create index if not exists idx_doodle_recipients_doodle_id on public.doodle_recipients(doodle_id);
create index if not exists idx_friendships_requester_id on public.friendships(requester_id);
create index if not exists idx_friendships_addressee_id on public.friendships(addressee_id);
create index if not exists idx_users_invite_code on public.users(invite_code);

-- ============================================
-- FUNCTION TO GENERATE UNIQUE INVITE CODES
-- ============================================
create or replace function generate_invite_code()
returns text as $$
declare
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i int;
begin
  for i in 1..8 loop
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  end loop;
  return result;
end;
$$ language plpgsql;

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
alter table public.users enable row level security;
alter table public.doodles enable row level security;
alter table public.doodle_recipients enable row level security;
alter table public.friendships enable row level security;

-- ============================================
-- RLS POLICIES: USERS
-- ============================================
-- Anyone authenticated can read any user's public info
create policy "Users are viewable by authenticated users"
  on public.users for select
  to authenticated
  using (true);

-- Users can only update their own row
create policy "Users can update own profile"
  on public.users for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- Users can insert their own row (for initial profile creation)
create policy "Users can insert own profile"
  on public.users for insert
  to authenticated
  with check (auth.uid() = id);

-- ============================================
-- RLS POLICIES: DOODLES
-- ============================================
-- Users can read doodles they sent
create policy "Users can view own sent doodles"
  on public.doodles for select
  to authenticated
  using (sender_id = auth.uid());

-- Users can read doodles sent to them (via doodle_recipients)
create policy "Users can view received doodles"
  on public.doodles for select
  to authenticated
  using (
    exists (
      select 1 from public.doodle_recipients
      where doodle_recipients.doodle_id = doodles.id
      and doodle_recipients.recipient_id = auth.uid()
    )
  );

-- Users can only insert doodles as themselves
create policy "Users can insert own doodles"
  on public.doodles for insert
  to authenticated
  with check (sender_id = auth.uid());

-- Users can delete their own sent doodles
create policy "Users can delete own doodles"
  on public.doodles for delete
  to authenticated
  using (sender_id = auth.uid());

-- ============================================
-- RLS POLICIES: DOODLE_RECIPIENTS
-- ============================================
-- Users can view recipient entries where they are the recipient
create policy "Users can view own received entries"
  on public.doodle_recipients for select
  to authenticated
  using (recipient_id = auth.uid());

-- Users can view recipient entries for doodles they sent
create policy "Senders can view recipient entries"
  on public.doodle_recipients for select
  to authenticated
  using (
    exists (
      select 1 from public.doodles
      where doodles.id = doodle_recipients.doodle_id
      and doodles.sender_id = auth.uid()
    )
  );

-- Users can insert recipient entries for their own doodles
create policy "Users can insert recipients for own doodles"
  on public.doodle_recipients for insert
  to authenticated
  with check (
    exists (
      select 1 from public.doodles
      where doodles.id = doodle_id
      and doodles.sender_id = auth.uid()
    )
  );

-- Recipients can update their own entry (e.g., mark as viewed)
create policy "Recipients can update own entry"
  on public.doodle_recipients for update
  to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

-- Recipients can delete their own entry (remove from their history)
create policy "Recipients can delete own entry"
  on public.doodle_recipients for delete
  to authenticated
  using (recipient_id = auth.uid());

-- ============================================
-- RLS POLICIES: FRIENDSHIPS
-- ============================================
-- Users can view friendships they're part of
create policy "Users can view own friendships"
  on public.friendships for select
  to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());

-- Users can create friend requests
create policy "Users can create friend requests"
  on public.friendships for insert
  to authenticated
  with check (requester_id = auth.uid());

-- Addressee can update friendship status (accept)
create policy "Addressee can accept friend request"
  on public.friendships for update
  to authenticated
  using (addressee_id = auth.uid())
  with check (addressee_id = auth.uid());

-- Either party can delete the friendship
create policy "Users can delete own friendships"
  on public.friendships for delete
  to authenticated
  using (requester_id = auth.uid() or addressee_id = auth.uid());
