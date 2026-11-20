-- Règles de l'incrément 6 : langues selon l'offre, statistiques.
-- Lancer : supabase test db
begin;
select plan(28);

-- La base locale peut contenir d'autres données : chaque vérification se limite aux
-- comptes créés ici.
insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'gratuit@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'mensuel@example.test'),
  ('00000000-0000-0000-0000-00000000000c', 'annuel@example.test');
insert into public.subscriptions (user_id, plan, expires_at, last_event_at)
values
  ('00000000-0000-0000-0000-00000000000b', 'monthly', now() + interval '20 days', now()),
  ('00000000-0000-0000-0000-00000000000c', 'annual', now() + interval '200 days', now());

create function pg_temp.act_as(p_user uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
                    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
$$;

-- Journal corrigé au jour [p_days_ago], avec [p_mistakes] fautes de conjugaison.
create function pg_temp.corrected(
  p_user uuid, p_language public.language_code, p_days_ago integer,
  p_sentences integer default 2, p_mistakes integer default 0
) returns void language plpgsql as $$
declare
  v_entry_id uuid;
begin
  insert into public.journal_entries (
    user_id, language, entry_date, original_text, corrected_text, sentence_count,
    idempotency_key, corrected_at
  ) values (
    p_user, p_language, current_date - p_days_ago, 'Texte.', 'Texte.', p_sentences,
    gen_random_uuid(), now()
  ) returning id into v_entry_id;
  insert into public.correction_items (entry_id, position, original, corrected, category, explanation)
  select v_entry_id, n, 'a', 'b', 'conjugation', 'Explication'
    from generate_series(1, p_mistakes) as n;
end;
$$;

grant execute on function pg_temp.act_as(uuid) to authenticated;

-- ── Gratuit : une langue à la fois ──────────────────────────────────────────
set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');

select lives_ok($$ select public.activate_language('en') $$, 'gratuit : choisit l''anglais');
select lives_ok($$ select public.activate_language('es') $$, 'gratuit : passe à l''espagnol');
select is(public.get_languages(), '{es}'::public.language_code[],
  'gratuit : la nouvelle langue remplace l''ancienne');
select throws_ok($$ select public.deactivate_language('es') $$, 'P0001', 'last_language',
  'la dernière langue ne peut pas être retirée');

-- ── Premium mensuel : jusqu'à 3 langues ─────────────────────────────────────
select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');

select lives_ok($$ select public.activate_language('en') $$, 'mensuel : anglais');
select lives_ok($$ select public.activate_language('es') $$, 'mensuel : ajoute l''espagnol');
select lives_ok($$ select public.activate_language('de') $$, 'mensuel : ajoute l''allemand');
select is(public.get_languages(), '{de,es,en}'::public.language_code[],
  'mensuel : trois langues, la dernière choisie d''abord');
select throws_ok($$ select public.activate_language('fr') $$, 'P0001', 'language_limit',
  'mensuel : une quatrième langue est refusée');
select lives_ok($$ select public.activate_language('en') $$,
  'mensuel : revenir à une langue déjà active est permis à la limite');
select is(public.get_languages(), '{en,de,es}'::public.language_code[],
  'mensuel : la langue choisie devient la langue en cours, sans retirer les autres');
select lives_ok($$ select public.deactivate_language('es') $$, 'mensuel : retire l''espagnol');
select is(public.get_languages(), '{en,de}'::public.language_code[],
  'mensuel : la langue retirée disparaît');
select lives_ok($$ select public.activate_language('fr') $$,
  'mensuel : une place libérée permet une autre langue');

-- ── Premium annuel : les 4 langues ──────────────────────────────────────────
select pg_temp.act_as('00000000-0000-0000-0000-00000000000c');
select lives_ok($$
  select public.activate_language('en'), public.activate_language('es'),
         public.activate_language('de'), public.activate_language('fr')
$$, 'annuel : active les quatre langues');
select is(cardinality(public.get_languages()), 4, 'annuel : quatre langues utilisables');

-- ── Fin d'abonnement : une seule langue reste utilisable ─────────────────────
reset role;
update public.subscriptions set expires_at = now() - interval '1 day'
 where user_id = '00000000-0000-0000-0000-00000000000c';

select is(
  array(select language from public.usable_languages('00000000-0000-0000-0000-00000000000c')),
  '{fr}'::public.language_code[],
  'abonnement terminé : seule la dernière langue choisie reste utilisable'
);
select is(
  (select count(*)::int from public.user_languages
    where user_id = '00000000-0000-0000-0000-00000000000c' and is_active),
  4,
  'abonnement terminé : les autres langues sont conservées'
);
select is(
  public.reserve_correction('00000000-0000-0000-0000-00000000000c', 'en', current_date,
                            'Hello.', gen_random_uuid()) ->> 'reason',
  'language_not_active',
  'abonnement terminé : pas de correction dans une langue devenue inutilisable'
);
select is(
  public.reserve_correction('00000000-0000-0000-0000-00000000000c', 'fr', current_date,
                            'Bonjour.', gen_random_uuid()) ->> 'status',
  'reserved',
  'abonnement terminé : la langue en cours reste corrigée'
);
select is(
  public.pick_exercises('00000000-0000-0000-0000-00000000000c', 'en', 'fr', current_date, 3)
    ->> 'reason',
  'language_not_active',
  'les exercices ne sont servis que dans une langue utilisable'
);

-- ── Statistiques ────────────────────────────────────────────────────────────
-- Gratuit : journaux aujourd'hui, hier, avant-hier, puis un trou ; un en espagnol.
select pg_temp.corrected('00000000-0000-0000-0000-00000000000a', 'es', 0);
select pg_temp.corrected('00000000-0000-0000-0000-00000000000a', 'en', 1);
select pg_temp.corrected('00000000-0000-0000-0000-00000000000a', 'es', 2);
select pg_temp.corrected('00000000-0000-0000-0000-00000000000a', 'es', 4);
-- Mensuel : rien aujourd'hui, mais hier et avant-hier ; 3 fautes sur 4 phrases.
select pg_temp.corrected('00000000-0000-0000-0000-00000000000b', 'en', 1, 2, 1);
select pg_temp.corrected('00000000-0000-0000-0000-00000000000b', 'en', 2, 2, 2);
insert into public.vocabulary_items (user_id, entry_id, language, term, translation, example, learned_at)
select '00000000-0000-0000-0000-00000000000b', id, 'en', 'word ' || n, 'mot', 'Example.',
       case when n = 1 then now() end
  from public.journal_entries, generate_series(1, 2) as n
 where user_id = '00000000-0000-0000-0000-00000000000b' and entry_date = current_date - 1;

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');

select is(
  public.get_stats('es', current_date) - 'week_days',
  '{"is_premium": false, "streak_days": 3, "journals": 3}'::jsonb,
  'gratuit : série toutes langues confondues et nombre de journaux de la langue, sans plus'
);
select is(
  public.get_stats('es', current_date) -> 'week_days',
  (select coalesce(jsonb_agg(day order by day), '[]'::jsonb)
     from unnest(array[current_date, current_date - 1, current_date - 2, current_date - 4]) as day
    where day >= date_trunc('week', current_date)::date),
  'jours écrits de la semaine en cours, du lundi à aujourd''hui, toutes langues confondues'
);
select is(
  public.get_stats('es', date '1990-01-01') ->> 'streak_days',
  '3',
  'une date d''appareil invraisemblable est remplacée par celle du serveur'
);

select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');
select is(
  public.get_stats('en', current_date) ->> 'streak_days',
  '2',
  'la série tient tant que le dernier journal date d''hier'
);
select is(
  public.get_stats('en', current_date) - array['weekly_mistake_rate', 'week_days'],
  '{"is_premium": true, "streak_days": 2, "journals": 2, "words_learned": 1, "words_total": 2,
    "mistakes_by_category": [{"category": "conjugation", "count": 3}]}'::jsonb,
  'Premium : mots appris et fautes par catégorie'
);
select is(
  (select sum((week ->> 'mistakes_per_sentence')::numeric * 2)
     from jsonb_array_elements(public.get_stats('en', current_date) -> 'weekly_mistake_rate') as week)
    in (1.5, 2.0 + 1.0),
  true,
  'Premium : fautes par phrase, semaine par semaine (3 sur 4, ou 1 sur 2 puis 2 sur 2)'
);

-- Un journal il y a deux jours, rien depuis : la série est perdue.
reset role;
select pg_temp.corrected('00000000-0000-0000-0000-00000000000c', 'fr', 2);
set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000c');
select is(
  public.get_stats('fr', current_date) ->> 'streak_days',
  '0',
  'la série est perdue après un jour sans journal'
);

select * from finish();
rollback;
