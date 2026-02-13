-- ============================================
-- SQUIBBLE DATABASE SCHEMA
-- Migration: 008_conversations_schema
-- Date: 2026-02-03
-- Description: Add conversations, conversation_participants, and thread_items tables
-- for conversation threading feature
-- ============================================
--
-- ROLLBACK INSTRUCTIONS:
-- To undo this migration, run the following:
--
-- DROP POLICY IF EXISTS "Users can view conversations they participate in" ON public.conversations;
-- DROP POLICY IF EXISTS "Users can view their own participation" ON public.conversation_participants;
-- DROP POLICY IF EXISTS "Users can view co-participants" ON public.conversation_participants;
-- DROP POLICY IF EXISTS "Users can update their own participation" ON public.conversation_participants;
-- DROP POLICY IF EXISTS "Users can view thread items in their conversations" ON public.thread_items;
-- DROP POLICY IF EXISTS "Users can insert thread items as sender" ON public.thread_items;
-- DROP INDEX IF EXISTS idx_thread_items_conversation_time;
-- DROP INDEX IF EXISTS idx_conversation_participants_user;
-- DROP INDEX IF EXISTS idx_conversations_updated;
-- DROP TABLE IF EXISTS public.thread_items;
-- DROP TABLE IF EXISTS public.conversation_participants;
-- DROP TABLE IF EXISTS public.conversations;
--
-- ============================================

-- 1. CONVERSATIONS TABLE
-- ============================================
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('direct', 'group')),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 2. CONVERSATION PARTICIPANTS TABLE
-- ============================================
create table if not exists public.conversation_participants (
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  last_read_at timestamp with time zone default now(),
  muted boolean default false,
  joined_at timestamp with time zone default now(),
  primary key (conversation_id, user_id)
);

-- 3. THREAD ITEMS TABLE (unified timeline for doodles + text)
-- ============================================
create table if not exists public.thread_items (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  sender_id uuid references public.users(id) not null,
  type text not null check (type in ('doodle', 'text')),
  doodle_id uuid references public.doodles(id) on delete cascade,
  text_content text,
  reply_to_item_id uuid references public.thread_items(id),
  created_at timestamp with time zone default now(),
  constraint valid_doodle check (type != 'doodle' or doodle_id is not null),
  constraint valid_text check (type != 'text' or text_content is not null)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
create index if not exists idx_thread_items_conversation_time
  on public.thread_items(conversation_id, created_at desc);

create index if not exists idx_conversation_participants_user
  on public.conversation_participants(user_id);

create index if not exists idx_conversations_updated
  on public.conversations(updated_at desc);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.thread_items enable row level security;

-- ============================================
-- RLS POLICIES: CONVERSATIONS
-- ============================================
-- Users can view conversations they participate in
create policy "Users can view conversations they participate in"
  on public.conversations for select
  to authenticated
  using (
    exists (
      select 1 from public.conversation_participants
      where conversation_participants.conversation_id = conversations.id
      and conversation_participants.user_id = auth.uid()
    )
  );

-- ============================================
-- RLS POLICIES: CONVERSATION_PARTICIPANTS
-- ============================================
-- Users can view their own participation records
create policy "Users can view their own participation"
  on public.conversation_participants for select
  to authenticated
  using (user_id = auth.uid());

-- Users can view co-participants in their conversations
create policy "Users can view co-participants"
  on public.conversation_participants for select
  to authenticated
  using (
    exists (
      select 1 from public.conversation_participants cp
      where cp.conversation_id = conversation_participants.conversation_id
      and cp.user_id = auth.uid()
    )
  );

-- Users can update their own participation (muted, last_read_at)
create policy "Users can update their own participation"
  on public.conversation_participants for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ============================================
-- RLS POLICIES: THREAD_ITEMS
-- ============================================
-- Users can view thread items in conversations they participate in
create policy "Users can view thread items in their conversations"
  on public.thread_items for select
  to authenticated
  using (
    exists (
      select 1 from public.conversation_participants
      where conversation_participants.conversation_id = thread_items.conversation_id
      and conversation_participants.user_id = auth.uid()
    )
  );

-- Users can insert thread items as the sender (only in conversations they're in)
create policy "Users can insert thread items as sender"
  on public.thread_items for insert
  to authenticated
  with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversation_participants
      where conversation_id = thread_items.conversation_id
      and user_id = auth.uid()
    )
  );
