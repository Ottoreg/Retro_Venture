-- Base du jeu en ligne (GDD § 16.5, jalon M1), à coller une fois dans Supabase → SQL Editor → Run.
-- Les comptes sont ceux de Supabase Auth (auth.users). Le serveur de jeu écrit avec la clé secrète
-- (qui passe outre la sécurité par ligne) ; le client ne lit que l'adresse du serveur vivant.

-- Personnages : un par compte pour le prototype, pseudo unique (sans tenir compte des majuscules),
-- état complet en JSON (World.player_save : personnage, carte, position).
create table if not exists public.personnages (
  compte uuid primary key references auth.users (id) on delete cascade,
  pseudo text not null,
  pseudo_min text generated always as (lower(pseudo)) stored unique,
  race text not null,
  voie text not null,
  niveau integer not null default 1,
  carte text not null,
  etat jsonb not null,
  maj timestamptz not null default now()
);
alter table public.personnages enable row level security;
-- Aucune règle : seul le serveur (clé secrète) lit et écrit les personnages.

-- Serveur actuel : une seule ligne, rafraîchie toutes les 30 s par le serveur qui tourne. Sert de
-- garde-fou (un seul poste à la fois) et donne son adresse publique aux clients.
create table if not exists public.serveur_actuel (
  id integer primary key check (id = 1),
  adresse text not null default '',
  instance text not null default '',
  poste text not null default '',
  vu timestamptz not null default now()
);
alter table public.serveur_actuel enable row level security;

-- Serveur vivant (marqueur de moins de 90 s) : lisible par tous les clients.
create or replace view public.serveur_en_ligne as
  select adresse, instance, poste, vu from public.serveur_actuel
  where vu > now() - interval '90 seconds';
grant select on public.serveur_en_ligne to anon, authenticated;
