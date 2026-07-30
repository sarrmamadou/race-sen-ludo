-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°4
-- Personnalisation d'image par bercail (les 4 zones de départ à 6x6 cases)
-- =========================================================================

alter table public.sponsor_config add column if not exists yard_images jsonb default '{}'::jsonb;

-- =========================================================================
-- Fin de la migration n°4.
-- =========================================================================
