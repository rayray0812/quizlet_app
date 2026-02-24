-- Add avatar_url and bio columns to profiles table.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url text DEFAULT '';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS bio text DEFAULT '';

-- Create public avatars storage bucket.
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- RLS: users can upload/update/delete their own avatar folder.
CREATE POLICY "Users can manage own avatar"
  ON storage.objects FOR ALL
  USING (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- RLS: anyone can read avatars (public bucket).
CREATE POLICY "Public avatar read access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');
