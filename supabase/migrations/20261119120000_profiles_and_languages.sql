-- Inc-1 : profils et langues pratiquées (US-01 à US-03).
-- Toute écriture passe par des fonctions ; l'app ne fait que lire ses propres lignes.

create type public.language_code as enum ('en', 'es', 'de', 'fr');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.user_languages (
  user_id uuid not null references public.profiles (id) on delete cascade,
  language public.language_code not null,
  is_active boolean not null default true,
  activated_at timestamptz not null default now(),
  primary key (user_id, language)
);

-- Accès : lecture de ses propres lignes uniquement.
alter table public.profiles enable row level security;
alter table public.user_languages enable row level security;

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.user_languages from anon, authenticated;
grant select on table public.profiles to authenticated;
grant select on table public.user_languages to authenticated;

create policy profiles_select_own on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

create policy user_languages_select_own on public.user_languages
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- Un profil est créé avec chaque compte.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Active une langue pour l'utilisateur courant.
-- Offre gratuite : une seule langue active à la fois (INTAKE §2.10) ; l'historique des
-- autres langues est conservé, elles sont seulement désactivées.
create function public.activate_language(p_language public.language_code)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  update public.user_languages
     set is_active = false
   where user_id = v_user_id
     and language <> p_language
     and is_active;

  insert into public.user_languages (user_id, language)
  values (v_user_id, p_language)
  on conflict (user_id, language)
  do update set is_active = true, activated_at = now();
end;
$$;

revoke execute on function public.activate_language(public.language_code) from public, anon;
grant execute on function public.activate_language(public.language_code) to authenticated;

-- Suppression du compte par son titulaire (US-03). La cascade efface toutes ses données.
create function public.delete_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  delete from auth.users where id = v_user_id;
end;
$$;

revoke execute on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
