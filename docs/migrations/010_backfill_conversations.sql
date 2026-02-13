-- ============================================
-- SQUIBBLE DATA MIGRATION
-- Migration: 010_backfill_conversations
-- Date: 2026-02-03
-- Description: Backfill existing doodles into conversations and thread_items
-- ============================================
--
-- IMPORTANT: Run this migration ONCE after applying 008 and 009.
-- This script is idempotent (safe to run multiple times) due to
-- ON CONFLICT DO NOTHING clauses.
--
-- ROLLBACK INSTRUCTIONS:
-- To undo the backfilled data (but keep the tables), run:
--
-- DELETE FROM public.thread_items WHERE id IN (
--   SELECT ti.id FROM public.thread_items ti
--   JOIN public.doodles d ON d.id = ti.doodle_id
-- );
-- DELETE FROM public.conversation_participants;
-- DELETE FROM public.conversations;
--
-- ============================================

do $$
declare
  rec record;
  conv_id uuid;
  existing_item_count int;
begin
  -- Log start
  raise notice 'Starting conversation backfill migration...';

  -- Count existing thread_items to detect re-runs
  select count(*) into existing_item_count from thread_items;
  if existing_item_count > 0 then
    raise notice 'Found % existing thread_items - this appears to be a re-run', existing_item_count;
  end if;

  -- Process each doodle with its recipients
  -- Order by created_at to maintain chronological order
  for rec in
    select
      d.id as doodle_id,
      d.sender_id,
      dr.recipient_id,
      d.created_at
    from doodles d
    join doodle_recipients dr on dr.doodle_id = d.id
    order by d.created_at asc
  loop
    -- Get or create conversation between sender and recipient
    conv_id := get_or_create_direct_conversation(rec.sender_id, rec.recipient_id);

    -- Create thread item for this doodle (skip if already exists)
    insert into thread_items (conversation_id, sender_id, type, doodle_id, created_at)
    values (conv_id, rec.sender_id, 'doodle', rec.doodle_id, rec.created_at)
    on conflict do nothing;

    -- Update conversation's updated_at to match the latest doodle
    update conversations
    set updated_at = greatest(updated_at, rec.created_at)
    where id = conv_id;

  end loop;

  -- Log completion
  raise notice 'Backfill complete. Created thread_items for existing doodles.';

  -- Report statistics
  raise notice 'Total conversations: %', (select count(*) from conversations);
  raise notice 'Total thread_items: %', (select count(*) from thread_items);
  raise notice 'Total participants: %', (select count(*) from conversation_participants);

end $$;
