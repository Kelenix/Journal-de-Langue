-- Règles d'accès et fonctions de l'incrément 1. Lancer : supabase test db
begin;
select plan(17);

-- Deux comptes ; le trigger crée leur profil.
insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'a@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@example.test');

select is(
  (select count(*)::int from public.profiles
    where id in ('00000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-00000000000b')),
  2,
  'un profil est créé pour chaque nouveau compte'
);

select is(
  (select bool_and(relrowsecurity) from pg_class
    where oid in ('public.profiles'::regclass, 'public.user_languages'::regclass)),
  true,
  'RLS est activée sur profiles et user_languages'
);

-- Utilisateur A
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

select lives_ok($$ select public.activate_language('en') $$, 'A active l''anglais');
select lives_ok($$ select public.activate_language('es') $$, 'A passe à l''espagnol');

select is(
  (select array_agg(language::text order by language) from public.user_languages where is_active),
  array['es'],
  'offre gratuite : une seule langue active, la dernière choisie'
);
select is(
  (select count(*)::int from public.user_languages),
  2,
  'la langue précédente est conservée, désactivée'
);

select lives_ok($$ select public.activate_language('en') $$, 'A revient à l''anglais');
select is(
  (select array_agg(language::text order by language) from public.user_languages where is_active),
  array['en'],
  'réactiver une langue déjà connue la rend seule active'
);

select throws_ok(
  $$ insert into public.user_languages (user_id, language)
     values ('00000000-0000-0000-0000-00000000000a', 'de') $$,
  '42501', null,
  'l''app ne peut pas insérer une langue directement'
);
select throws_ok(
  $$ update public.user_languages set is_active = true $$,
  '42501', null,
  'l''app ne peut pas modifier ses langues directement'
);
select throws_ok(
  $$ delete from public.profiles $$,
  '42501', null,
  'l''app ne peut pas supprimer un profil directement'
);

-- Utilisateur B ne voit rien de A.
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';

select is((select count(*)::int from public.user_languages), 0, 'B ne voit pas les langues de A');
select is((select count(*)::int from public.profiles), 1, 'B ne voit que son propre profil');

-- Suppression du compte de B.
select lives_ok($$ select public.delete_account() $$, 'B supprime son compte');

reset role;
select is(
  (select count(*)::int from auth.users where id = '00000000-0000-0000-0000-00000000000b'),
  0,
  'le compte de B n''existe plus'
);
select is(
  (select count(*)::int from public.user_languages where user_id = '00000000-0000-0000-0000-00000000000a'),
  2,
  'les données de A sont intactes après la suppression de B'
);

-- Visiteur non connecté.
set local role anon;
set local request.jwt.claims = '{"role": "anon"}';
select throws_ok(
  $$ select public.activate_language('fr') $$,
  '42501', null,
  'un visiteur non connecté ne peut pas appeler activate_language'
);

select * from finish();
rollback;
