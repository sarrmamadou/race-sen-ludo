-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°10
-- Ajoute l'email du joueur directement sur sa demande d'abonnement, pour
-- que l'administrateur le voie sans avoir à chercher ailleurs.
-- =========================================================================

alter table public.subscription_requests add column if not exists email text;

-- =========================================================================
-- Fin de la migration n°10.
-- =========================================================================
