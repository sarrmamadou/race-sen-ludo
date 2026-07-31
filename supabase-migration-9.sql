-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°9
-- Le schéma "auth" est protégé et en lecture seule dans le tableau de bord
-- Supabase : impossible d'y créer un nouveau trigger/webhook depuis
-- l'interface. On enrichit donc directement la fonction handle_new_user()
-- existante (déclenchée par le trigger système on_auth_user_created) pour
-- qu'elle notifie aussi contact@race-senegal.sn à chaque inscription.
-- =========================================================================

create extension if not exists pg_net;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role) values (new.id, 'player')
  on conflict (id) do nothing;

  perform net.http_post(
    url := 'https://fkclffjtkwkuvharihev.supabase.co/functions/v1/notify-admin',
    headers := jsonb_build_object('Content-Type','application/json'),
    body := jsonb_build_object(
      'table', 'users',
      'record', jsonb_build_object('email', new.email, 'created_at', new.created_at)
    )
  );

  return new;
end;
$$;

-- =========================================================================
-- Fin de la migration n°9.
-- =========================================================================
