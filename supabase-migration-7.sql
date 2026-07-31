-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°7
-- Upload de fichiers audio pour la playlist musicale (en plus des URLs)
-- =========================================================================

insert into storage.buckets (id, name, public)
values ('sponsor-audio', 'sponsor-audio', true)
on conflict (id) do nothing;

create policy "sponsor-audio public read" on storage.objects
  for select using (bucket_id = 'sponsor-audio');

create policy "sponsor-audio admin insert" on storage.objects
  for insert with check (
    bucket_id = 'sponsor-audio' and
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "sponsor-audio admin update" on storage.objects
  for update using (
    bucket_id = 'sponsor-audio' and
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "sponsor-audio admin delete" on storage.objects
  for delete using (
    bucket_id = 'sponsor-audio' and
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- =========================================================================
-- Fin de la migration n°7.
-- =========================================================================
