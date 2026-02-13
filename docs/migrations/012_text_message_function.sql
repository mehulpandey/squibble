-- ============================================
-- SQUIBBLE DATABASE FUNCTION
-- Migration: 012_text_message_function
-- Date: 2026-02-04
-- Description: Add function to create text message thread items
-- ============================================
--
-- ROLLBACK INSTRUCTIONS:
-- DROP FUNCTION IF EXISTS create_text_thread_item(uuid, uuid, text);
--
-- ============================================

-- CREATE TEXT THREAD ITEM
-- ============================================
-- Creates a thread item for a text message in a conversation.
-- Also updates the conversation's updated_at timestamp.
-- Uses SECURITY DEFINER to ensure atomicity.

create or replace function create_text_thread_item(
  p_conversation_id uuid,
  p_sender_id uuid,
  p_text_content text
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
  insert into thread_items (conversation_id, sender_id, type, text_content)
  values (p_conversation_id, p_sender_id, 'text', p_text_content)
  returning id into item_id;

  -- Update conversation's updated_at timestamp
  update conversations
  set updated_at = now()
  where id = p_conversation_id;

  return item_id;
end;
$$ language plpgsql security definer;

-- Grant execute to authenticated users
grant execute on function create_text_thread_item(uuid, uuid, text) to authenticated;
