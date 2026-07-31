-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°8
-- Permet à un admin de retrouver l'UUID d'un compte à partir de son email,
-- sans exposer les emails de tous les joueurs publiquement. Réservé aux
-- comptes admin (vérifié à l'intérieur de la fonction elle-même).
-- =========================================================================

create or replace function public.find_user_id_by_email(target_email text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  requester_role text;
  found_id uuid;
begin
  select role into requester_role from public.profiles where id = auth.uid();
  if requester_role is distinct from 'admin' then
    raise exception 'Accès refusé : réservé aux administrateurs.';
  end if;

  select id into found_id from auth.users where email = target_email;
  return found_id;
end;
$$;

grant execute on function public.find_user_id_by_email(text) to authenticated;

-- =========================================================================
-- Fin de la migration n°8.
-- =========================================================================
