-- Migration: 014_aggregated_reactions_function.sql
-- Description: Functions to get aggregated reactions for doodles across all thread_items
-- This enables showing combined reactions when a doodle is sent to multiple people

-- Get all reactions for a single doodle across all thread_items
create or replace function get_aggregated_reactions_for_doodle(p_doodle_id uuid)
returns table (
  doodle_id uuid,
  user_id uuid,
  display_name text,
  profile_image_url text,
  color_hex text,
  emoji text
) as $$
begin
  return query
  select
    ti.doodle_id,
    r.user_id,
    u.display_name,
    u.profile_image_url,
    u.color_hex,
    r.emoji
  from reactions r
  join thread_items ti on ti.id = r.thread_item_id
  join users u on u.id = r.user_id
  where ti.doodle_id = p_doodle_id;
end;
$$ language plpgsql security definer;

-- Batch version: Get aggregated reactions for multiple doodles (for grid view efficiency)
create or replace function get_aggregated_reactions_for_doodles(p_doodle_ids uuid[])
returns table (
  doodle_id uuid,
  user_id uuid,
  display_name text,
  profile_image_url text,
  color_hex text,
  emoji text
) as $$
begin
  return query
  select
    ti.doodle_id,
    r.user_id,
    u.display_name,
    u.profile_image_url,
    u.color_hex,
    r.emoji
  from reactions r
  join thread_items ti on ti.id = r.thread_item_id
  join users u on u.id = r.user_id
  where ti.doodle_id = any(p_doodle_ids);
end;
$$ language plpgsql security definer;
