-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°3
-- Personnalisation d'image par case (URL ou upload de fichier par l'admin)
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. Colonne pour stocker une image par case (clé = index de case 0..51,
--    valeur = URL de l'image). Vide par défaut ; retombe sur cell_img
--    (l'image générique déjà existante) si une case n'a rien de spécifique.
-- ---------------------------------------------------------------------
alter table public.sponsor_config add column if not exists cell_images jsonb default '{}'::jsonb;

-- ---------------------------------------------------------------------
-- 2. Bucket de stockage public pour les images uploadées par l'admin
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('sponsor-images', 'sponsor-images', true)
on conflict (id) do nothing;

-- Lecture publique (tout le monde doit pouvoir voir les images du plateau)
create policy "sponsor-images public read" on storage.objects
  for select using (bucket_id = 'sponsor-images');

-- Upload / modification / suppression réservés aux comptes admin
create policy "sponsor-images admin insert" on storage.objects
  for insert with check (
    bucket_id = 'sponsor-images' and
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "sponsor-images admin update" on storage.objects
  for update using (
    bucket_id = 'sponsor-images' and
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "sponsor-images admin delete" on storage.objects
  for delete using (
    bucket_id = 'sponsor-images' and
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- =========================================================================
-- Fin de la migration n°3.
-- =========================================================================
