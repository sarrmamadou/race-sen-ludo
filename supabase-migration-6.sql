-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°6
-- Sélection pragmatique des participants d'un tournoi par l'admin, parmi
-- les comptes déjà inscrits (au lieu d'un tournoi ouvert à tous par défaut).
-- =========================================================================

create table if not exists public.tournament_participants (
  id bigserial primary key,
  tournament_id uuid references public.tournaments(id) on delete cascade,
  user_id uuid references auth.users(id),
  added_at timestamptz default now(),
  unique(tournament_id, user_id)
);

alter table public.tournament_participants enable row level security;

create policy "tparts: public read" on public.tournament_participants
  for select using (true);

create policy "tparts: admin insert" on public.tournament_participants
  for insert with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

create policy "tparts: admin delete" on public.tournament_participants
  for delete using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

grant select, insert, delete on public.tournament_participants to authenticated;
grant select on public.tournament_participants to anon;
grant usage, select on all sequences in schema public to authenticated;

-- =========================================================================
-- Fin de la migration n°6.
-- =========================================================================
