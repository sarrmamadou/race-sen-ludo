-- =========================================================================
-- RACE-SEN-LUDO — migration additionnelle n°11
-- Moyens de paiement multiples pour l'abonnement web (en plus du QR Wave) :
-- numéros Orange Money / Wave / Djamo, et infos de virement bancaire.
-- =========================================================================

alter table public.sponsor_config add column if not exists payment_orange_money text;
alter table public.sponsor_config add column if not exists payment_wave_number text;
alter table public.sponsor_config add column if not exists payment_djamo text;
alter table public.sponsor_config add column if not exists payment_bank_info text;

-- =========================================================================
-- Fin de la migration n°11.
-- =========================================================================
