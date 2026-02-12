-- Migration: 015_batch_conversation_query.sql
-- Description: RPC function to load conversations with metadata in a single query
-- Eliminates N+1 queries for latest items and unread counts

-- Returns all conversations for a user with latest item and unread count
CREATE OR REPLACE FUNCTION get_conversations_with_metadata(p_user_id uuid)
RETURNS TABLE (
  conversation_id uuid,
  conversation_type text,
  conversation_updated_at timestamptz,
  other_user_id uuid,
  other_user_display_name text,
  other_user_color_hex text,
  other_user_profile_image_url text,
  my_last_read_at timestamptz,
  my_muted boolean,
  latest_item_id uuid,
  latest_item_type text,
  latest_item_sender_id uuid,
  latest_item_doodle_id uuid,
  latest_item_text_content text,
  latest_item_created_at timestamptz,
  unread_count bigint
) AS $$
BEGIN
  RETURN QUERY
  WITH my_participations AS (
    -- Get all conversations I'm part of
    SELECT
      cp.conversation_id as mp_conv_id,
      cp.last_read_at as mp_last_read_at,
      cp.muted as mp_muted
    FROM conversation_participants cp
    WHERE cp.user_id = p_user_id
  ),
  other_participants AS (
    -- Get the other user in each conversation (for 1:1 chats)
    SELECT
      cp.conversation_id as op_conv_id,
      cp.user_id as op_user_id,
      u.display_name as op_display_name,
      u.color_hex as op_color_hex,
      u.profile_image_url as op_profile_image_url
    FROM conversation_participants cp
    JOIN users u ON u.id = cp.user_id
    WHERE cp.user_id != p_user_id
      AND cp.conversation_id IN (SELECT mp_conv_id FROM my_participations)
  ),
  latest_items AS (
    -- Get the most recent thread item for each conversation
    SELECT DISTINCT ON (ti.conversation_id)
      ti.conversation_id as li_conv_id,
      ti.id as li_id,
      ti.type as li_type,
      ti.sender_id as li_sender_id,
      ti.doodle_id as li_doodle_id,
      ti.text_content as li_text_content,
      ti.created_at as li_created_at
    FROM thread_items ti
    WHERE ti.conversation_id IN (SELECT mp_conv_id FROM my_participations)
    ORDER BY ti.conversation_id, ti.created_at DESC
  ),
  unread_counts AS (
    -- Count unread items per conversation
    SELECT
      ti.conversation_id as uc_conv_id,
      COUNT(*) as uc_cnt
    FROM thread_items ti
    JOIN my_participations mp ON mp.mp_conv_id = ti.conversation_id
    WHERE ti.created_at > COALESCE(mp.mp_last_read_at, '1970-01-01'::timestamptz)
      AND ti.sender_id != p_user_id
    GROUP BY ti.conversation_id
  )
  SELECT
    c.id as conversation_id,
    c.type::text as conversation_type,
    c.updated_at as conversation_updated_at,
    op.op_user_id as other_user_id,
    op.op_display_name as other_user_display_name,
    op.op_color_hex as other_user_color_hex,
    op.op_profile_image_url as other_user_profile_image_url,
    mp.mp_last_read_at as my_last_read_at,
    mp.mp_muted as my_muted,
    li.li_id as latest_item_id,
    li.li_type as latest_item_type,
    li.li_sender_id as latest_item_sender_id,
    li.li_doodle_id as latest_item_doodle_id,
    li.li_text_content as latest_item_text_content,
    li.li_created_at as latest_item_created_at,
    COALESCE(uc.uc_cnt, 0) as unread_count
  FROM conversations c
  JOIN my_participations mp ON mp.mp_conv_id = c.id
  JOIN other_participants op ON op.op_conv_id = c.id
  LEFT JOIN latest_items li ON li.li_conv_id = c.id
  LEFT JOIN unread_counts uc ON uc.uc_conv_id = c.id
  ORDER BY COALESCE(li.li_created_at, c.updated_at) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_conversations_with_metadata(uuid) TO authenticated;
