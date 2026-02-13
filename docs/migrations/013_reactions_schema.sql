-- ============================================
-- SQUIBBLE DATABASE SCHEMA
-- Migration: 013_reactions_schema
-- Date: 2026-02-04
-- Description: Add reactions table for thread item reactions
-- ============================================
--
-- ROLLBACK INSTRUCTIONS:
-- DROP INDEX IF EXISTS idx_reactions_thread_item;
-- DROP TABLE IF EXISTS public.reactions;
--
-- ============================================

-- 1. REACTIONS TABLE
-- ============================================
-- Stores emoji reactions to thread items (doodles or text messages)
-- One reaction per user per thread item (can change emoji, but only one active)

create table if not exists public.reactions (
  id uuid primary key default gen_random_uuid(),
  thread_item_id uuid references public.thread_items(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  emoji text not null,
  created_at timestamp with time zone default now(),
  unique(thread_item_id, user_id)  -- one reaction per user per item
);

-- 2. INDEX FOR FAST LOOKUPS
-- ============================================
create index if not exists idx_reactions_thread_item
  on public.reactions(thread_item_id);

-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================
alter table public.reactions enable row level security;

-- 4. RLS POLICIES
-- ============================================

-- Users can view reactions on thread items in conversations they participate in
create policy "Users can view reactions in their conversations"
  on public.reactions for select
  to authenticated
  using (
    exists (
      select 1 from public.thread_items ti
      join public.conversation_participants cp on cp.conversation_id = ti.conversation_id
      where ti.id = reactions.thread_item_id
      and cp.user_id = auth.uid()
    )
  );

-- Users can add reactions to thread items in conversations they participate in
create policy "Users can add reactions in their conversations"
  on public.reactions for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.thread_items ti
      join public.conversation_participants cp on cp.conversation_id = ti.conversation_id
      where ti.id = reactions.thread_item_id
      and cp.user_id = auth.uid()
    )
  );

-- Users can delete their own reactions
create policy "Users can delete their own reactions"
  on public.reactions for delete
  to authenticated
  using (user_id = auth.uid());

-- Users can update their own reactions (change emoji)
create policy "Users can update their own reactions"
  on public.reactions for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
