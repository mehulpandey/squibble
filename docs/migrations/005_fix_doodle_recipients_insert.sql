-- ============================================
-- SQUIBBLE DATABASE SCHEMA
-- Migration: 005_fix_doodle_recipients_insert
-- Date: 2025-01-08
-- Description: Fix RLS INSERT policy for doodle_recipients
-- The previous policy incorrectly referenced doodle_recipients.doodle_id
-- which doesn't work during INSERT. We need to reference the NEW row values.
-- ============================================

-- Drop the broken insert policy
drop policy if exists "Senders can insert doodle recipients" on public.doodle_recipients;
drop policy if exists "Users can insert recipients for own doodles" on public.doodle_recipients;

-- Create corrected insert policy
-- For INSERT, with_check receives the NEW row values directly (not table-qualified)
create policy "Senders can insert doodle recipients"
  on public.doodle_recipients for insert
  to authenticated
  with check (
    exists (
      select 1 from public.doodles
      where doodles.id = doodle_id
      and doodles.sender_id = auth.uid()
    )
  );
