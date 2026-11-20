-- Phase 5 (ADR-041) : envois rejoués, tentatives ratées plafonnées, abonnements dans le
-- désordre, exercices générés mal formés. Lancer : supabase test db
begin;
select plan(16);

-- La base locale peut contenir d'autres données : chaque vérification se limite aux comptes
-- et aux lignes créés ici.
insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-0000000000c1', 'gratuit@example.test'),
  ('00000000-0000-0000-0000-0000000000c2', 'premium@example.test'),
  ('00000000-0000-0000-0000-0000000000c3', 'abonne@example.test');
insert into public.user_languages (user_id, language)
values
  ('00000000-0000-0000-0000-0000000000c1', 'en'),
  ('00000000-0000-0000-0000-0000000000c2', 'en');
insert into public.subscriptions (user_id, plan, expires_at, last_event_at)
values ('00000000-0000-0000-0000-0000000000c2', 'monthly', now() + interval '20 days', now());

create function pg_temp.reserve(p_key uuid) returns jsonb language sql as $$
  select public.reserve_correction(
    '00000000-0000-0000-0000-0000000000c1', 'en', current_date, 'Hello.', p_key);
$$;

create function pg_temp.fail(p_user uuid, p_feature text, p_count integer) returns void
language sql as $$
  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens, succeeded)
  select p_user, p_feature, 'claude-haiku-5-5', 100, 10, false
    from generate_series(1, p_count);
$$;

-- ── Correction : même envoi rejoué ──────────────────────────────────────────
select is(pg_temp.reserve('20000000-0000-0000-0000-000000000001') ->> 'status', 'reserved',
  'première demande : réservée');
select is(pg_temp.reserve('20000000-0000-0000-0000-000000000001'), '{"status": "busy"}'::jsonb,
  'même envoi pendant la correction : un seul appel à Claude');

update public.journal_entries set created_at = now() - interval '3 minutes'
 where idempotency_key = '20000000-0000-0000-0000-000000000001';
select is(pg_temp.reserve('20000000-0000-0000-0000-000000000001') ->> 'status', 'reserved',
  'réservation abandonnée depuis plus de 2 minutes : remplacée');

-- Journal corrigé il y a 10 jours : la RLS le cache en gratuit, la reprise aussi.
insert into public.journal_entries (user_id, language, entry_date, original_text,
                                    corrected_text, sentence_count, idempotency_key,
                                    corrected_at)
values ('00000000-0000-0000-0000-0000000000c1', 'en', current_date - 10, 'Old.', 'Old.', 1,
        '20000000-0000-0000-0000-000000000002', now() - interval '10 days');
select is(
  pg_temp.reserve('20000000-0000-0000-0000-000000000002'),
  '{"status": "denied", "reason": "history_locked"}'::jsonb,
  'reprise d''un journal hors de l''historique lisible : refusée');

-- ── Correction : tentatives ratées ──────────────────────────────────────────
delete from public.journal_entries
 where user_id = '00000000-0000-0000-0000-0000000000c1' and corrected_at is null;
select pg_temp.fail('00000000-0000-0000-0000-0000000000c1', 'correction_basic', 9);
insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
select '00000000-0000-0000-0000-0000000000c1', 'correction_basic', 'claude-haiku-5-5', 100, 10
  from generate_series(1, 3);
select is(pg_temp.reserve('20000000-0000-0000-0000-000000000003') ->> 'status', 'reserved',
  '9 appels ratés en 24 h (les réussis ne comptent pas) : la correction reste possible');

delete from public.journal_entries
 where user_id = '00000000-0000-0000-0000-0000000000c1' and corrected_at is null;
select pg_temp.fail('00000000-0000-0000-0000-0000000000c1', 'correction_basic', 1);
select is(
  pg_temp.reserve('20000000-0000-0000-0000-000000000004'),
  '{"status": "denied", "reason": "too_many_attempts"}'::jsonb,
  '10 appels ratés en 24 h : plus de tentative');

-- ── Reformulations : les refus comptent dans la limite du jour ──────────────
insert into public.journal_entries (id, user_id, language, entry_date, original_text,
                                    corrected_text, sentence_count, idempotency_key,
                                    corrected_at)
values ('00000000-0000-0000-0000-0000000000d1', '00000000-0000-0000-0000-0000000000c2', 'en',
        current_date, 'I has a cat.', 'I have a cat.', 1, gen_random_uuid(), now());
select pg_temp.fail(
  '00000000-0000-0000-0000-0000000000c2', 'rewrite',
  (select daily_rewrites - 1 from public.plan_limits('00000000-0000-0000-0000-0000000000c2')));
select is(
  public.reserve_rewrite('00000000-0000-0000-0000-0000000000c2',
                         '00000000-0000-0000-0000-0000000000d1', 'I have a cat.') ->> 'status',
  'needed', 'sous la limite du jour : reformulation possible');
select pg_temp.fail('00000000-0000-0000-0000-0000000000c2', 'rewrite', 1);
select is(
  public.reserve_rewrite('00000000-0000-0000-0000-0000000000c2',
                         '00000000-0000-0000-0000-0000000000d1', 'I have a cat.') ->> 'reason',
  'rewrite_limit', 'les refus de Claude comptent dans la limite des reformulations');

-- ── Examen : notation longue, tentatives ratées ─────────────────────────────
insert into public.exams (id, user_id, language, level, ui_locale, status, prompt, updated_at)
values ('00000000-0000-0000-0000-0000000000e9', '00000000-0000-0000-0000-0000000000c2', 'en',
        'B1', 'fr', 'grading', '{"task": "Écris."}', now() - interval '2 minutes');
create function pg_temp.claim() returns jsonb language sql as $$
  select public.claim_exam_grading('00000000-0000-0000-0000-0000000000c2',
                                   '00000000-0000-0000-0000-0000000000e9', 'My essay.');
$$;
select is(pg_temp.claim(), '{"status": "busy"}'::jsonb,
  'notation lancée il y a 2 minutes : toujours en cours');
update public.exams set updated_at = now() - interval '4 minutes'
 where id = '00000000-0000-0000-0000-0000000000e9';
select is(pg_temp.claim() ->> 'status', 'claimed',
  'notation arrêtée en route depuis plus de 3 minutes : relancée');
update public.exams set status = 'in_progress'
 where id = '00000000-0000-0000-0000-0000000000e9';
select pg_temp.fail('00000000-0000-0000-0000-0000000000c2', 'exam_grading', 5);
select is(pg_temp.claim(), '{"status": "denied", "reason": "too_many_attempts"}'::jsonb,
  '5 notations ratées en 24 h : plus de tentative');

-- ── Abonnements : événements de deux formules ───────────────────────────────
create function pg_temp.event(p_id text, p_type text, p_product text, p_expires interval,
                              p_ago interval) returns text language sql as $$
  select public.apply_subscription_event(
    p_id, '00000000-0000-0000-0000-0000000000c3', p_type, p_product, now() + p_expires,
    false, now() - p_ago);
$$;
select pg_temp.event('evt-w1', 'INITIAL_PURCHASE', 'premium_weekly', interval '4 days',
                     interval '3 days');
select pg_temp.event('evt-a1', 'INITIAL_PURCHASE', 'premium_annual', interval '360 days',
                     interval '2 days');
select is(
  pg_temp.event('evt-w2', 'EXPIRATION', 'premium_weekly', interval '-1 hour', interval '1 hour'),
  'stale', 'expiration de l''hebdomadaire remplacé : ignorée');
select is(
  (select plan::text from public.subscriptions
    where user_id = '00000000-0000-0000-0000-0000000000c3' and expires_at > now()),
  'annual', 'l''abonnement annuel reste actif');

-- ── Exercices générés : un exercice mal formé n'empêche pas les autres ──────
select is(
  public.add_exercises(
    '00000000-0000-0000-0000-0000000000c1', 'fr', 'spelling', 'en',
    '[{"question": "Bon", "options": ["a", "b", "c", "d"], "answer_index": 2, "explanation": "x"},
      {"question": "Décimal", "options": ["a", "b", "c", "d"], "answer_index": 1.5,
       "explanation": "x"},
      {"question": "Sans liste", "options": "a", "answer_index": 0, "explanation": "x"}]'::jsonb,
    'claude-haiku-5-5', 10, 10),
  1, 'seul l''exercice bien formé est ajouté, sans erreur');

-- ── Droits ──────────────────────────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims =
  '{"sub": "00000000-0000-0000-0000-0000000000c1", "role": "authenticated"}';
select throws_ok(
  $$ select public.failed_ai_calls('00000000-0000-0000-0000-0000000000c2', 'correction_%') $$,
  '42501', null, 'l''app ne compte pas les appels d''un autre utilisateur');
select throws_ok(
  $$ select public.history_start_date('00000000-0000-0000-0000-0000000000c2') $$,
  '42501', null, 'l''app ne lit pas la fenêtre d''historique d''un autre utilisateur');

select * from finish();
rollback;
