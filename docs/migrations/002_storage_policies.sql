-- ============================================
-- STORAGE POLICIES FOR DOODLES BUCKET
-- Migration: 002_storage_policies
-- Date: 2024-12-27
-- Description: Storage bucket policies for doodle images
-- Note: Create bucket named "doodles" first via Supabase Dashboard
-- ============================================

-- Allow authenticated users to upload to their own folder
create policy "Users can upload own doodles"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'doodles'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Allow authenticated users to read any doodle (RLS on doodles table handles access)
create policy "Authenticated users can read doodles"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'doodles');

-- Allow users to delete their own uploaded doodles
create policy "Users can delete own doodles"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'doodles'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
