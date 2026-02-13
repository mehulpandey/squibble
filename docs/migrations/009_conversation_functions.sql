-- ============================================
-- SQUIBBLE DATABASE FUNCTIONS
-- Migration: 009_conversation_functions
-- Date: 2026-02-03
-- Description: Helper functions for conversation operations
-- ============================================
--
-- ROLLBACK INSTRUCTIONS:
-- To undo this migration, run the following:
--
-- DROP FUNCTION IF EXISTS get_or_create_direct_conversation(uuid, uuid);
-- DROP FUNCTION IF EXISTS create_thread_item_for_doodle(uuid, uuid, uuid);
--
-- ============================================

-- 1. GET OR CREATE DIRECT CONVERSATION
-- ============================================
-- Returns the conversation ID for a direct conversation between two users.
-- Creates the conversation and participants if it doesn't exist.
-- Uses SECURITY DEFINER to bypass RLS for INSERT operations.

create or replace function get_or_create_direct_conversation(
  user_a uuid,
  user_b uuid
) returns uuid as $$
declare
  conv_id uuid;
begin
  -- Find existing direct conversation between these two users
  -- A direct conversation has exactly these two users as participants
  select cp1.conversation_id into conv_id
  from conversation_participants cp1
  join conversation_participants cp2 on cp1.conversation_id = cp2.conversation_id
  join conversations c on c.id = cp1.conversation_id
  where cp1.user_id = user_a
    and cp2.user_id = user_b
    and c.type = 'direct';

  -- If no conversation exists, create one
  if conv_id is null then
    -- Create the conversation
    insert into conversations (type)
    values ('direct')
    returning id into conv_id;

    -- Add both users as participants
    insert into conversation_participants (conversation_id, user_id)
    values (conv_id, user_a);

    insert into conversation_participants (conversation_id, user_id)
    values (conv_id, user_b);
  end if;

  return conv_id;
end;
$$ language plpgsql security definer;

-- Grant execute to authenticated users
grant execute on function get_or_create_direct_conversation(uuid, uuid) to authenticated;


-- 2. CREATE THREAD ITEM FOR DOODLE
-- ============================================
-- Creates a thread item linking a doodle to a conversation.
-- Also updates the conversation's updated_at timestamp.
-- Uses SECURITY DEFINER to ensure atomicity.

create or replace function create_thread_item_for_doodle(
  p_conversation_id uuid,
  p_sender_id uuid,
  p_doodle_id uuid
) returns uuid as $$
declare
  item_id uuid;
begin
  -- Verify sender is a participant in the conversation
  if not exists (
    select 1 from conversation_participants
    where conversation_id = p_conversation_id
    and user_id = p_sender_id
  ) then
    raise exception 'Sender is not a participant in this conversation';
  end if;

  -- Create the thread item
  insert into thread_items (conversation_id, sender_id, type, doodle_id)
  values (p_conversation_id, p_sender_id, 'doodle', p_doodle_id)
  returning id into item_id;

  -- Update conversation's updated_at timestamp
  update conversations
  set updated_at = now()
  where id = p_conversation_id;

  return item_id;
end;
$$ language plpgsql security definer;

-- Grant execute to authenticated users
grant execute on function create_thread_item_for_doodle(uuid, uuid, uuid) to authenticated;
