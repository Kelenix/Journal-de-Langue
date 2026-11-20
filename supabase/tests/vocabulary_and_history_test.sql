-- Règles de l'incrément 3 : vocabulaire à réviser, historique limité. Lancer : supabase test db
begin;
select plan(20);

-- La base locale peut contenir d'autres données : chaque vérification faite avec le rôle
-- propriétaire se limite aux comptes créés ici.
insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'a@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@example.test');
insert into public.user_languages (user_id, language)
values ('00000000-0000-0000-0000-00000000000a', 'en');

-- Journal en cours de correction pour A, à la date donnée.
create function pg_temp.pending_entry(p_date date) returns uuid language sql as $$
  insert into public.journal_entries
    (user_id, language, entry_date, original_text, sentence_count, idempotency_key)
  values
    ('00000000-0000-0000-0000-00000000000a', 'en', p_date, 'Some text.', 1, gen_random_uuid())
  returning id;
$$;

create function pg_temp.complete(p_entry uuid, p_vocabulary jsonb) returns void language sql as $$
  select public.complete_correction(
    p_entry, 'Some text.', '[]'::jsonb, p_vocabulary, 'claude-haiku-5-5', 10, 10);
$$;

create function pg_temp.words(variadic p_terms text[]) returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object(
           'term', term, 'translation', 'traduction', 'example', 'Example.') order by position)
    from unnest(p_terms) with ordinality as word (term, position);
$$;

create function pg_temp.terms_of_a() returns text[] language sql as $$
  select coalesce(array_agg(term order by created_at, term), '{}')
    from public.vocabulary_items
   where user_id = '00000000-0000-0000-0000-00000000000a';
$$;

-- ── Vocabulaire enregistré avec la correction ───────────────────────────────
select lives_ok(
  $$ select pg_temp.complete(
       pg_temp.pending_entry(current_date - 1),
       pg_temp.words('grocery store', 'to run out of', '  ', 'Grocery Store')) $$,
  'une correction enregistre son vocabulaire'
);
select is(
  pg_temp.terms_of_a(),
  array['grocery store', 'to run out of'],
  'terme vide ignoré, doublon (à la casse près) ignoré'
);
select is(
  (select row(language, translation, example, learned_at is null)::text
     from public.vocabulary_items
    where user_id = '00000000-0000-0000-0000-00000000000a' and term = 'grocery store'),
  '(en,traduction,Example.,t)',
  'chaque mot garde sa langue, sa traduction, son exemple, et n''est pas encore appris'
);

select lives_ok(
  $$ select pg_temp.complete(
       pg_temp.pending_entry(current_date),
       pg_temp.words('one', 'two', 'three', 'four', 'five', 'six', 'seven')) $$,
  'une correction propose plus de mots que la limite du jour'
);
select is(
  (select count(*)::int from public.vocabulary_items as word
     join public.journal_entries as entry on entry.id = word.entry_id
    where word.user_id = '00000000-0000-0000-0000-00000000000a'
      and entry.entry_date = current_date),
  5,
  'offre gratuite : 5 mots par jour au plus'
);
select lives_ok(
  $$ select pg_temp.complete(pg_temp.pending_entry(current_date), pg_temp.words('eight')) $$,
  'une seconde correction le même jour reste possible côté vocabulaire'
);
select is(
  (select count(*)::int from public.vocabulary_items
    where user_id = '00000000-0000-0000-0000-00000000000a' and term = 'eight'),
  0,
  'la limite du jour atteinte, aucun mot n''est ajouté'
);

-- ── Historique : journaux anciens conservés mais non lisibles ───────────────
select lives_ok(
  $$ select pg_temp.complete(pg_temp.pending_entry(current_date - 30), '[]'::jsonb) $$,
  'un journal ancien existe en base'
);

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

select is(
  (select array_agg(distinct entry_date order by entry_date) from public.journal_entries),
  array[current_date - 1, current_date],
  'A ne lit que ses journaux des derniers jours'
);
select is(
  public.get_history_overview(),
  '{"history_days": 4, "locked_entries": 1, "corrected_entries": 4}'::jsonb,
  'A sait qu''un journal plus ancien est conservé, et combien il en a en tout'
);

-- ── Accès au vocabulaire ────────────────────────────────────────────────────
select is(
  (select count(*)::int from public.vocabulary_items),
  7,
  'A lit tout son vocabulaire, même celui de journaux anciens'
);
select lives_ok(
  $$ update public.vocabulary_items set learned_at = now() where term = 'grocery store' $$,
  'A marque un mot comme appris'
);
select is(
  (select count(*)::int from public.vocabulary_items where learned_at is not null),
  1,
  'le mot est compté comme appris'
);
select throws_ok(
  $$ update public.vocabulary_items set term = 'triche' $$,
  '42501', null,
  'A ne peut pas modifier le contenu d''un mot'
);
select throws_ok(
  $$ insert into public.vocabulary_items (user_id, entry_id, language, term, translation, example)
     select user_id, entry_id, language, 'ajout', 'x', 'x' from public.vocabulary_items limit 1 $$,
  '42501', null,
  'A ne peut pas ajouter un mot directement'
);
select throws_ok(
  $$ select public.complete_correction(
       gen_random_uuid(), 'x', '[]'::jsonb, '[]'::jsonb, 'm', 1, 1) $$,
  '42501', null,
  'l''app ne peut pas enregistrer une correction elle-même'
);

set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';

select is(
  (select count(*)::int from public.vocabulary_items),
  0,
  'B ne voit pas le vocabulaire de A'
);
select is(
  public.get_history_overview(),
  '{"history_days": 4, "locked_entries": 0, "corrected_entries": 0}'::jsonb,
  'B n''a aucun journal, verrouillé ou non'
);
select lives_ok(
  $$ update public.vocabulary_items set learned_at = now() $$,
  'B tente de marquer tous les mots comme appris'
);

reset role;
select is(
  (select count(*)::int from public.vocabulary_items
    where user_id = '00000000-0000-0000-0000-00000000000a' and learned_at is not null),
  1,
  'la tentative de B n''a touché aucun mot de A'
);

select * from finish();
rollback;
