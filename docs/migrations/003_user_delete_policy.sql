-- ============================================
-- SQUIBBLE DATABASE SCHEMA
-- Migration: 003_user_delete_policy
-- Date: 2025-01-07
-- Description: Add RLS policy to allow users to delete their own account
-- ============================================

-- Drop existing policy if it exists (for re-running migration safely)
drop policy if exists "Users can delete own profile" on public.users;

-- Users can delete their own profile (for account deletion)
create policy "Users can delete own profile"
  on public.users for delete
  to authenticated
  using (auth.uid() = id);
