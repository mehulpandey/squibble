-- ============================================
-- SQUIBBLE DATABASE FIX
-- Migration: 011_fix_rls_recursion
-- Date: 2026-02-04
-- Description: Fix infinite recursion in conversation_participants RLS policy
-- ============================================
--
-- ROLLBACK INSTRUCTIONS:
-- This migration cannot be easily rolled back as it modifies RLS policies.
-- To restore the original state, re-run 008_conversations_schema.sql
--
-- ============================================

-- 1. DROP THE PROBLEMATIC POLICY
-- ============================================
-- This policy causes infinite recursion because it queries conversation_participants
-- to check if the user is a participant
drop policy if exists "Users can view co-participants" on public.conversation_participants;

-- 2. CREATE HELPER FUNCTION TO GET CONVERSATION PARTICIPANTS
-- ============================================
-- Uses SECURITY DEFINER to bypass RLS and avoid recursion
create or replace function get_conversation_participants(p_conversation_ids uuid[])
returns table (
  conversation_id uuid,
  user_id uuid,
  last_read_at timestamp with time zone,
  muted boolean,
  joined_at timestamp with time zone
) as $$
begin
  -- First verify the caller is a participant in at least one of these conversations
  if not exists (
    select 1 from public.conversation_participants cp
    where cp.conversation_id = any(p_conversation_ids)
    and cp.user_id = auth.uid()
  ) then
    return; -- Return empty if user isn't a participant in any
  end if;

  -- Return participants only for conversations the user is actually in
  return query
  select cp.conversation_id, cp.user_id, cp.last_read_at, cp.muted, cp.joined_at
  from public.conversation_participants cp
  where cp.conversation_id = any(p_conversation_ids)
  and cp.conversation_id in (
    select cp2.conversation_id from public.conversation_participants cp2
    where cp2.user_id = auth.uid()
  );
end;
$$ language plpgsql security definer;

-- Grant execute to authenticated users
grant execute on function get_conversation_participants(uuid[]) to authenticated;
