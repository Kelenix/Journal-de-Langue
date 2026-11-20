-- Règles de l'incrément 5 : niveau de correction, reformulations, exercices.
-- Lancer : supabase test db
begin;
select plan(31);

-- La base locale peut contenir d'autres données : chaque vérification faite avec le rôle
-- propriétaire se limite aux comptes et aux exercices créés ici (langue allemande, absente
-- des données de démonstration).
-- Les tests d'intégration peuvent avoir rempli la réserve allemande : elle est vidée le
-- temps de ce test, annulé à la fin.
delete from public.exercises where language = 'de';
insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'gratuit@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'premium@example.test');
insert into public.user_languages (user_id, language)
values
  ('00000000-0000-0000-0000-00000000000a', 'de'),
  ('00000000-0000-0000-0000-00000000000b', 'de');
insert into public.subscriptions (user_id, plan, expires_at, last_event_at)
values ('00000000-0000-0000-0000-00000000000b', 'monthly', now() + interval '20 days', now());

create function pg_temp.reserve(p_user uuid, p_text text) returns jsonb language sql as $$
  select public.reserve_correction(p_user, 'de', current_date, p_text, gen_random_uuid());
$$;

create function pg_temp.pick(p_user uuid, p_count integer default 3) returns jsonb language sql as $$
  select public.pick_exercises(p_user, 'de', 'fr', current_date, p_count);
$$;

create function pg_temp.generated(p_count integer, p_prefix text) returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object(
    'question', p_prefix || ' ' || n,
    'options', '["a", "b", "c", "d"]'::jsonb,
    'answer_index', 1,
    'explanation', 'Explication ' || n))
  from generate_series(1, p_count) as n;
$$;

-- ── Niveau de correction ────────────────────────────────────────────────────
select is(
  pg_temp.reserve('00000000-0000-0000-0000-00000000000a', 'Ich bin hier.') ->> 'level',
  'basic',
  'gratuit : correction de base'
);
select is(
  pg_temp.reserve('00000000-0000-0000-0000-00000000000b', 'Ich habe gegangen.') ->> 'level',
  'advanced',
  'Premium : correction avancée'
);
select lives_ok(
  $$ select public.complete_correction(
       (select id from public.journal_entries
         where user_id = '00000000-0000-0000-0000-00000000000b'),
       'Ich bin gegangen. Das ist schön.',
       '[{"original": "habe", "corrected": "bin", "category": "conjugation", "explanation": "x"},
         {"original": "x", "corrected": "y", "category": "conjugation", "explanation": "x"},
         {"original": "z", "corrected": "w", "category": "spelling", "explanation": "x"}]'::jsonb,
       '[]'::jsonb, 'claude-sonnet-5-5', 100, 200) $$,
  'la correction avancée est enregistrée'
);
select is(
  (select feature || '/' || model from public.ai_usage
    where user_id = '00000000-0000-0000-0000-00000000000b'),
  'correction_advanced/claude-sonnet-5-5',
  'son coût est journalisé à part de la correction de base'
);

-- ── Reformulations ──────────────────────────────────────────────────────────
select lives_ok(
  $$ select public.complete_correction(
       (select id from public.journal_entries
         where user_id = '00000000-0000-0000-0000-00000000000a'),
       'Ich bin hier.', '[]'::jsonb, '[]'::jsonb, 'claude-haiku-5-5', 10, 10) $$,
  'le journal du compte gratuit est corrigé'
);
select is(
  public.reserve_rewrite(
    '00000000-0000-0000-0000-00000000000a',
    (select id from public.journal_entries where user_id = '00000000-0000-0000-0000-00000000000a'),
    'Ich bin hier.') ->> 'reason',
  'premium_required',
  'gratuit : la reformulation est réservée à Premium'
);

create function pg_temp.rewrite(p_sentence text, p_user uuid default '00000000-0000-0000-0000-00000000000b')
returns jsonb language sql as $$
  select public.reserve_rewrite(
    p_user,
    (select id from public.journal_entries where user_id = '00000000-0000-0000-0000-00000000000b'),
    p_sentence);
$$;

select is(pg_temp.rewrite('Das ist schön.'), '{"status": "needed", "language": "de"}'::jsonb,
          'Premium : une phrase de son journal corrigé peut être reformulée');
select is(pg_temp.rewrite('Diese Phrase gibt es nicht.') ->> 'reason', 'invalid_sentence',
          'une phrase absente du journal est refusée');
select is(
  pg_temp.rewrite('Das ist schön.', '00000000-0000-0000-0000-00000000000a') ->> 'reason',
  'premium_required',
  'impossible de reformuler via le journal d''un autre sans être Premium'
);
insert into public.subscriptions (user_id, plan, expires_at, last_event_at)
values ('00000000-0000-0000-0000-00000000000a', 'weekly', now() + interval '1 day', now());
select is(
  pg_temp.rewrite('Das ist schön.', '00000000-0000-0000-0000-00000000000a') ->> 'reason',
  'invalid_sentence',
  'même Premium, impossible de reformuler une phrase du journal d''un autre'
);
delete from public.subscriptions where user_id = '00000000-0000-0000-0000-00000000000a';

select lives_ok(
  $$ select public.save_rewrite(
       '00000000-0000-0000-0000-00000000000b',
       (select id from public.journal_entries where user_id = '00000000-0000-0000-0000-00000000000b'),
       'Das ist schön.', 'poli', 'familier', 'pro', 'claude-haiku-5-5', 20, 30) $$,
  'la reformulation est conservée'
);
select is(
  pg_temp.rewrite('Das ist schön.'),
  '{"status": "cached", "rewrite": {"polite": "poli", "casual": "familier", "professional": "pro"}}'::jsonb,
  'redemander la même phrase rend la reformulation conservée, sans nouvel appel'
);

-- ── Exercices : choix et réserve ────────────────────────────────────────────
select is(
  pg_temp.pick('00000000-0000-0000-0000-00000000000b'),
  '{"status": "need_generation", "category": "conjugation"}'::jsonb,
  'Premium : exercices sur son erreur la plus fréquente ; réserve vide, génération demandée'
);
select is(
  public.add_exercises(
    '00000000-0000-0000-0000-00000000000b', 'de', 'conjugation', 'fr',
    pg_temp.generated(5, 'Conjugaison')
      || '[{"question": "mal formé", "options": ["a", "b"], "answer_index": 0, "explanation": "x"},
           {"question": "index faux", "options": ["a", "b", "c", "d"], "answer_index": 7, "explanation": "x"}]'::jsonb,
    'claude-haiku-5-5', 50, 300),
  5,
  'les exercices mal formés sont écartés de la réserve'
);
select is(
  (select row(p ->> 'status', (p ->> 'is_personalized')::boolean, (p ->> 'left')::int,
              jsonb_array_length(p -> 'exercises'))::text
     from pg_temp.pick('00000000-0000-0000-0000-00000000000b') as p),
  '(ok,t,20,3)',
  'Premium : 3 exercices personnalisés, 20 par jour'
);
select is(
  (select p -> 'exercises' -> 0 ? 'answer_index'
     from pg_temp.pick('00000000-0000-0000-0000-00000000000b') as p),
  false,
  'la bonne réponse n''est pas envoyée avec la question'
);

-- Le compte gratuit travaille le type du jour, commun à tous. Ce type change chaque jour
-- et retombe sur la conjugaison un jour sur sept : la réserve du compte Premium est vidée
-- pour que la vérification ne dépende pas de la date.
delete from public.exercises where language = 'de';
select is(
  pg_temp.pick('00000000-0000-0000-0000-00000000000a') ->> 'status',
  'need_generation',
  'gratuit : exercices génériques, réserve à constituer'
);
select lives_ok(
  $$ select public.add_exercises(
       '00000000-0000-0000-0000-00000000000a', 'de',
       (pg_temp.pick('00000000-0000-0000-0000-00000000000a') ->> 'category')::public.error_category,
       'fr', pg_temp.generated(5, 'Générique'), 'claude-haiku-5-5', 50, 300) $$,
  'la réserve du type du jour est constituée'
);
select is(
  (select row((p ->> 'is_personalized')::boolean, (p ->> 'left')::int,
              jsonb_array_length(p -> 'exercises'))::text
     from pg_temp.pick('00000000-0000-0000-0000-00000000000a', 10) as p),
  '(f,3,3)',
  'gratuit : exercices non personnalisés, 3 par jour même si l''app en demande 10'
);

-- ── Exercices : réponses ────────────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

select throws_ok(
  $$ select count(*) from public.exercises $$, '42501', null,
  'l''app ne lit pas la réserve d''exercices directement'
);
select throws_ok(
  $$ select public.pick_exercises(
       '00000000-0000-0000-0000-00000000000b', 'de', 'fr', current_date, 3) $$,
  '42501', null,
  'l''app ne peut pas tirer les exercices d''un autre utilisateur'
);

reset role;
create temporary table generic_ids on commit drop as
  select (exercise ->> 'id')::uuid as id, row_number() over () as position
    from jsonb_array_elements(
      pg_temp.pick('00000000-0000-0000-0000-00000000000a') -> 'exercises') as exercise;
-- Un quatrième exercice de la réserve, au-delà de la limite du jour.
insert into generic_ids (id, position)
select id, 4
  from public.exercises
 where language = 'de' and question like 'Générique %'
   and id not in (select id from generic_ids)
 limit 1;
grant select on generic_ids to authenticated;
set local role authenticated;

select is(
  (select row(a - 'explanation', a ->> 'explanation' like 'Explication %')::text
     from public.answer_exercise(
       (select id from generic_ids where position = 1), 1, current_date) as a),
  '("{""left"": 2, ""status"": ""ok"", ""is_correct"": true, ""answer_index"": 1}",t)',
  'bonne réponse : correction et explication rendues, 2 exercices restants'
);
select is(
  public.answer_exercise((select id from generic_ids where position = 2), 3, current_date)
    ->> 'is_correct',
  'false',
  'mauvaise réponse signalée'
);
select is(
  public.answer_exercise((select id from generic_ids where position = 3), 9, current_date)
    ->> 'reason',
  'invalid_answer',
  'un choix hors des 4 options est refusé sans compter'
);
select is(
  public.answer_exercise((select id from generic_ids where position = 3), 0, current_date)
    ->> 'left',
  '0',
  'troisième exercice du jour'
);
select is(
  public.answer_exercise((select id from generic_ids where position = 4), 1, current_date),
  '{"status": "limit"}'::jsonb,
  'gratuit : pas de quatrième réponse le même jour'
);
select is(
  (select row(a ->> 'status', a ->> 'is_correct', a ->> 'left')::text
     from public.answer_exercise(
       (select id from generic_ids where position = 1), 1, current_date) as a),
  '(ok,true,0)',
  'une réponse renvoyée rend son résultat sans compter un exercice de plus'
);
select is(
  public.answer_exercise((select id from generic_ids where position = 1), 1, current_date + 9)
    ->> 'reason',
  'invalid_date',
  'changer la date de l''appareil ne donne pas d''exercices en plus'
);
select is(
  (select count(*)::int from public.exercise_attempts), 3,
  'le compte gratuit lit ses 3 réponses'
);

reset role;
select is(
  pg_temp.pick('00000000-0000-0000-0000-00000000000a'),
  '{"status": "limit", "is_premium": false}'::jsonb,
  'limite du jour atteinte : plus d''exercice proposé'
);

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';
select is(
  (select count(*)::int from public.exercise_attempts), 0,
  'un utilisateur ne voit pas les réponses d''un autre'
);

select * from finish();
rollback;
