-- ============================================
-- SQUIBBLE DATABASE SCHEMA
-- Migration: 007_rpc_add_doodle_recipients
-- Date: 2025-01-08
-- Description: Create a secure RPC function to add doodle recipients
-- This bypasses the problematic RLS INSERT policy by using SECURITY DEFINER
-- ============================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS add_doodle_recipients(UUID, UUID[]);

-- Create a function that adds recipients for a doodle
-- Only succeeds if the caller is the sender of the doodle
CREATE OR REPLACE FUNCTION add_doodle_recipients(
    p_doodle_id UUID,
    p_recipient_ids UUID[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_sender_id UUID;
    v_recipient_id UUID;
BEGIN
    -- Verify the current user is the sender of this doodle
    SELECT sender_id INTO v_sender_id
    FROM doodles
    WHERE id = p_doodle_id;

    IF v_sender_id IS NULL THEN
        RAISE EXCEPTION 'Doodle not found';
    END IF;

    IF v_sender_id != auth.uid() THEN
        RAISE EXCEPTION 'Not authorized to add recipients to this doodle';
    END IF;

    -- Insert all recipients
    FOREACH v_recipient_id IN ARRAY p_recipient_ids
    LOOP
        INSERT INTO doodle_recipients (doodle_id, recipient_id)
        VALUES (p_doodle_id, v_recipient_id)
        ON CONFLICT (doodle_id, recipient_id) DO NOTHING;
    END LOOP;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_doodle_recipients(UUID, UUID[]) TO authenticated;
