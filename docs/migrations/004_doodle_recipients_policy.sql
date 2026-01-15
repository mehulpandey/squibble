-- ============================================
-- SQUIBBLE DATABASE SCHEMA
-- Migration: 004_doodle_recipients_policy
-- Date: 2025-01-07
-- Description: Fix RLS policy for doodle_recipients to allow senders to add recipients
-- ============================================

-- The existing policy should work, but there may be edge cases where the
-- subquery doesn't see the newly created doodle. Let's recreate with
-- explicit handling.

-- First, drop the existing insert policy
drop policy if exists "Users can insert recipients for own doodles" on public.doodle_recipients;

-- Create a new insert policy that allows authenticated users to insert
-- when they are the sender of the referenced doodle.
-- Using EXISTS to check if the doodle belongs to the current user.
create policy "Senders can insert doodle recipients"
  on public.doodle_recipients for insert
  to authenticated
  with check (
    (
      select sender_id from public.doodles where id = doodle_id
    ) = auth.uid()
  );

-- Also add a policy allowing senders to delete recipient entries (for cleanup)
drop policy if exists "Senders can delete doodle recipients" on public.doodle_recipients;

create policy "Senders can delete doodle recipients"
  on public.doodle_recipients for delete
  to authenticated
  using (
    (
      select sender_id from public.doodles where id = doodle_id
    ) = auth.uid()
  );
