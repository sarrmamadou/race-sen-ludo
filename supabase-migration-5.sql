-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°5
-- Abonnement annuel (1000 XOF), paiement via QR Wave Business + activation
-- manuelle par l'admin.
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. Date de fin d'abonnement sur le profil (null = jamais abonné)
-- ---------------------------------------------------------------------
alter table public.profiles add column if not exists subscription_active_until timestamptz;

-- Autoriser les admins à modifier N'IMPORTE QUEL profil (en plus de la policy
-- existante qui autorise chacun à modifier son propre profil) — nécessaire
-- pour activer l'abonnement d'un autre utilisateur.
create policy "profiles: admin update any" on public.profiles
  for update using (
    exists (select 1 from public.profiles p2 where p2.id = auth.uid() and p2.role = 'admin')
  );

-- ---------------------------------------------------------------------
-- 2. QR code Wave Business (image) dans la config sponsor existante
-- ---------------------------------------------------------------------
alter table public.sponsor_config add column if not exists wave_qr_url text;

-- ---------------------------------------------------------------------
-- 3. Demandes d'activation d'abonnement ("j'ai payé, merci de valider")
-- ---------------------------------------------------------------------
create table if not exists public.subscription_requests (
  id bigserial primary key,
  user_id uuid references auth.users(id),
  note text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz default now(),
  handled_at timestamptz,
  handled_by uuid references auth.users(id)
);

alter table public.subscription_requests enable row level security;

create policy "subreq: owner insert" on public.subscription_requests
  for insert with check (auth.uid() = user_id);

create policy "subreq: owner or admin read" on public.subscription_requests
  for select using (
    auth.uid() = user_id or
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "subreq: admin update" on public.subscription_requests
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

grant select, insert, update on public.subscription_requests to authenticated;

-- =========================================================================
-- Fin de la migration n°5.
-- =========================================================================
