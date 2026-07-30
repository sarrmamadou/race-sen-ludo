-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°2
-- À exécuter APRÈS supabase-schema.sql (celui-ci ne recrée rien qui existe
-- déjà, donc pas de conflit avec les policies déjà en place).
-- =========================================================================

-- ---------------------------------------------------------------------
-- 1. Nom d'affichage public (utilisé dans le classement des tournois,
--    pour ne jamais exposer l'email des joueurs publiquement).
-- ---------------------------------------------------------------------
alter table public.profiles add column if not exists display_name text;

update public.profiles pr
set display_name = split_part(u.email, '@', 1)
from auth.users u
where pr.id = u.id and pr.display_name is null;

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, role, display_name)
  values (new.id, 'player', split_part(new.email, '@', 1))
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

-- chacun peut aussi changer son propre display_name (déjà couvert par la
-- policy "profiles: update own (non-role)" existante).


-- ---------------------------------------------------------------------
-- 2. Playlist musicale (gérée par l'admin, dans sponsor_config).
-- ---------------------------------------------------------------------
alter table public.sponsor_config add column if not exists playlist jsonb default '[]'::jsonb;


-- ---------------------------------------------------------------------
-- 3. Tournois sponsorisés mensuels
-- ---------------------------------------------------------------------
create table if not exists public.tournaments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sponsor_name text,
  sponsor_logo_url text,
  prize_description text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  created_by uuid references auth.users(id),
  created_at timestamptz default now()
);

alter table public.tournaments enable row level security;

create policy "tournaments: public read" on public.tournaments
  for select using (true);
create policy "tournaments: admin write" on public.tournaments
  for insert with check (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );
create policy "tournaments: admin update" on public.tournaments
  for update using (
    exists (select 1 from public.profiles where id = auth.uid() and role = 'admin')
  );

-- rattacher une partie au tournoi en cours (nullable, rempli côté client)
alter table public.games add column if not exists tournament_id uuid references public.tournaments(id);


-- ---------------------------------------------------------------------
-- 4. Octroi des privilèges pour les nouveaux objets
-- ---------------------------------------------------------------------
grant select, insert, update on public.tournaments to authenticated;
grant select on public.tournaments to anon;
grant select on public.profiles to anon; -- nécessaire pour afficher display_name dans le classement public

-- =========================================================================
-- 5. Passer contact@race-senegal.sn en administrateur
--    (ce compte doit d'abord exister — inscrivez-le une fois via l'app ou
--    via /auth/v1/signup — puis lancez ceci) :
-- =========================================================================
-- update public.profiles set role = 'admin'
-- where id = (select id from auth.users where email = 'contact@race-senegal.sn');

-- =========================================================================
-- Fin de la migration n°2.
-- =========================================================================
