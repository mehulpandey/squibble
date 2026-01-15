-- ============================================
-- SQUIBBLE DATABASE SCHEMA
-- Migration: 006_force_fix_doodle_recipients_insert
-- Date: 2025-01-08
-- Description: Force fix the INSERT policy for doodle_recipients
-- This drops ALL insert policies and recreates the correct one.
-- The issue: INSERT policies cannot reference table-qualified columns
-- (doodle_recipients.doodle_id), they must use unqualified column names.
-- ============================================

-- Step 1: Drop ALL possible INSERT policies on doodle_recipients
-- (covering all possible naming variations)
DO $$
DECLARE
    pol record;
BEGIN
    FOR pol IN
        SELECT policyname
        FROM pg_policies
        WHERE tablename = 'doodle_recipients'
        AND cmd = 'INSERT'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.doodle_recipients', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- Step 2: Create the correct INSERT policy
-- IMPORTANT: For INSERT policies, WITH CHECK receives the NEW row values
-- We reference 'doodle_id' directly (not table-qualified) because
-- it refers to the value being inserted in the new row
CREATE POLICY "Senders can insert doodle recipients"
  ON public.doodle_recipients FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.doodles
      WHERE doodles.id = doodle_id
      AND doodles.sender_id = auth.uid()
    )
  );
