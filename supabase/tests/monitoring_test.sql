-- Suivi de l'incrément 9 : coût de l'IA par utilisateur et rétention à 7 jours (US-24).
-- Lancer : supabase test db
begin;
select plan(12);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000c', 'cout-a@example.test'),
  ('00000000-0000-0000-0000-00000000000d', 'cout-b@example.test'),
  ('00000000-0000-0000-0000-00000000000e', 'revenu-journal@example.test'),
  ('00000000-0000-0000-0000-00000000000f', 'revenu-exercice@example.test'),
  ('00000000-0000-0000-0000-000000000010', 'parti@example.test'),
  ('00000000-0000-0000-0000-000000000011', 'recent@example.test');

-- Dates UTC : un mois et une semaine d'inscription entièrement passés.
create temp table fixture as
select
  date_trunc('month', now() at time zone 'utc') - interval '2 months' as usage_month,
  date_trunc('week', now() at time zone 'utc') - interval '5 weeks' as cohort_week;

-- ── Coût de l'IA ────────────────────────────────────────────────────────────
insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens, created_at)
select usage.user_id::uuid, usage.feature, usage.model, usage.input_tokens,
       usage.output_tokens, (fixture.usage_month + interval '4 days') at time zone 'utc'
  from fixture,
       (values
         ('00000000-0000-0000-0000-00000000000c', 'correction_basic', 'claude-haiku-5-5',
          1000000, 200000),
         ('00000000-0000-0000-0000-00000000000c', 'exam_grading', 'claude-sonnet-5-5',
          100000, 10000),
         ('00000000-0000-0000-0000-00000000000c', 'correction_basic', 'modele-inconnu',
          5000, 500),
         ('00000000-0000-0000-0000-00000000000d', 'correction_basic', 'claude-haiku-5-5',
          500000, 0)
       ) as usage (user_id, feature, model, input_tokens, output_tokens);

select is(
  (select cost.cost_usd from public.v_ai_cost_per_user as cost, fixture
    where cost.user_id = '00000000-0000-0000-0000-00000000000c'
      and cost.month = fixture.usage_month::date),
  0.5000,
  'coût du mois : 0,10 $ + 0,10 $ pour Haiku, 0,20 $ + 0,10 $ pour Sonnet');
select is(
  (select cost.unpriced_calls from public.v_ai_cost_per_user as cost, fixture
    where cost.user_id = '00000000-0000-0000-0000-00000000000c'
      and cost.month = fixture.usage_month::date),
  1::bigint,
  'un modèle sans prix connu est signalé, pas compté pour zéro en silence');
select is(
  (select cost.calls from public.v_ai_cost_per_user as cost, fixture
    where cost.user_id = '00000000-0000-0000-0000-00000000000c'
      and cost.month = fixture.usage_month::date),
  3::bigint,
  'tous les appels du mois sont comptés');
select is(
  (select row(month.active_users, month.cost_usd, month.cost_per_active_user_usd)::text
     from public.v_ai_cost_per_month as month, fixture
    where month.month = fixture.usage_month::date),
  '(2,0.5500,0.2750)',
  'coût par utilisateur actif du mois');

-- ── Rétention à 7 jours ─────────────────────────────────────────────────────
update public.profiles as profile
   set created_at = (fixture.cohort_week + signup.offset_from_monday) at time zone 'utc'
  from fixture,
       (values
         ('00000000-0000-0000-0000-00000000000e', interval '1 day 9 hours'),
         ('00000000-0000-0000-0000-00000000000f', interval '2 days 9 hours'),
         ('00000000-0000-0000-0000-000000000010', interval '3 days 9 hours')
       ) as signup (user_id, offset_from_monday)
 where profile.id = signup.user_id::uuid;
update public.profiles set created_at = now() - interval '2 days'
 where id = '00000000-0000-0000-0000-000000000011';

-- Revenu le 7e jour avec un journal.
insert into public.journal_entries
  (user_id, language, entry_date, original_text, sentence_count, idempotency_key, created_at)
select '00000000-0000-0000-0000-00000000000e', 'en', (fixture.cohort_week + interval '8 days')::date,
       'I am back.', 1, gen_random_uuid(),
       (fixture.cohort_week + interval '8 days 10 hours') at time zone 'utc'
  from fixture;
-- Revenu le 7e jour avec un exercice.
insert into public.exercises (id, language, category, ui_locale, question, options,
                              answer_index, explanation)
values ('00000000-0000-0000-0000-0000000000e1', 'en', 'grammar', 'fr', 'She ___ nice.',
        '["is", "are", "be", "am"]', 0, 'Avec « she » : « is ».');
insert into public.exercise_attempts (user_id, exercise_id, attempt_date, choice, is_correct,
                                      created_at)
select '00000000-0000-0000-0000-00000000000f', '00000000-0000-0000-0000-0000000000e1',
       (fixture.cohort_week + interval '9 days')::date, 0, true,
       (fixture.cohort_week + interval '9 days 20 hours') at time zone 'utc'
  from fixture;
-- Revenu le 6e jour seulement : pas retenu.
insert into public.journal_entries
  (user_id, language, entry_date, original_text, sentence_count, idempotency_key, created_at)
select '00000000-0000-0000-0000-000000000010', 'en', (fixture.cohort_week + interval '9 days')::date,
       'Hello.', 1, gen_random_uuid(),
       (fixture.cohort_week + interval '9 days 10 hours') at time zone 'utc'
  from fixture;

select is(
  (select row(retention.signups, retention.retained_d7, retention.retention_d7_pct)::text
     from public.v_retention_d7 as retention, fixture
    where retention.cohort_week = fixture.cohort_week::date),
  '(3,2,66.7)',
  'rétention à 7 jours : journal ou exercice le 7e jour, pas le 6e');
select ok(
  not exists (
    select 1 from public.v_retention_d7
     where cohort_week = date_trunc('week', now() at time zone 'utc')::date),
  'une semaine dont le 7e jour n''est pas passé n''apparaît pas');

-- ── Accès : rôle service seulement ──────────────────────────────────────────
set local role authenticated;
select throws_ok('select * from public.v_ai_cost_per_user', '42501', null,
  'un utilisateur connecté ne lit pas le coût par utilisateur');
select throws_ok('select * from public.v_ai_cost_per_month', '42501', null,
  'ni le coût mensuel');
select throws_ok('select * from public.v_retention_d7', '42501', null,
  'ni la rétention');
select throws_ok('select * from public.ai_model_prices', '42501', null,
  'ni les prix des modèles');
reset role;

set local role anon;
select throws_ok('select * from public.v_ai_cost_per_user', '42501', null,
  'un visiteur non connecté non plus');
reset role;

set local role service_role;
select lives_ok('select * from public.v_ai_cost_per_month, public.v_retention_d7',
  'le rôle service lit les vues de suivi');
reset role;

select * from finish();
rollback;
