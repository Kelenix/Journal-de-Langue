-- Règles de l'incrément 8 : publicités et récompenses des vidéos.
-- Lancer : supabase test db
begin;
select plan(27);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'ancien@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'nouveau@example.test');
-- L'utilisateur A est inscrit depuis plus de 14 jours, B vient d'arriver.
update public.profiles set created_at = now() - interval '15 days'
 where id = '00000000-0000-0000-0000-00000000000a';
insert into public.user_languages (user_id, language)
values ('00000000-0000-0000-0000-00000000000a', 'de');

create function pg_temp.act_as(p_user uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
                    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.act_as(uuid) to authenticated;

create function pg_temp.reward(p_transaction text, p_kind public.ad_reward_kind,
                               p_user uuid default '00000000-0000-0000-0000-00000000000a')
returns text language sql as $$
  select public.grant_ad_reward(p_transaction, p_user, p_kind);
$$;

create function pg_temp.reserve() returns jsonb language sql as $$
  select public.reserve_correction(
    '00000000-0000-0000-0000-00000000000a', 'de', current_date, 'Hallo.', gen_random_uuid());
$$;

-- ── Qui voit des publicités ─────────────────────────────────────────────────
select ok(public.ads_enabled('00000000-0000-0000-0000-00000000000a'),
  'gratuit, inscrit depuis plus de 14 jours : publicités');
select ok(not public.ads_enabled('00000000-0000-0000-0000-00000000000b'),
  'pas de publicité pendant les 14 jours qui suivent l''inscription');

insert into public.wallets (user_id, ads_removed)
values ('00000000-0000-0000-0000-00000000000a', true);
select ok(not public.ads_enabled('00000000-0000-0000-0000-00000000000a'),
  'pas de publicité après l''achat « sans publicité »');
update public.wallets set ads_removed = false
 where user_id = '00000000-0000-0000-0000-00000000000a';

insert into public.subscriptions (user_id, plan, expires_at, last_event_at)
values ('00000000-0000-0000-0000-00000000000a', 'monthly', now() + interval '1 day', now());
select ok(not public.ads_enabled('00000000-0000-0000-0000-00000000000a'),
  'pas de publicité pour les abonnés Premium');
delete from public.subscriptions where user_id = '00000000-0000-0000-0000-00000000000a';

-- ── Récompenses ─────────────────────────────────────────────────────────────
select is(pg_temp.reward('ad-1', 'correction'), 'applied', 'une vidéo vue rapporte 1 correction');
select is(pg_temp.reward('ad-1', 'correction'), 'duplicate',
  'le même rappel d''AdMob ne compte qu''une fois');
select is(pg_temp.reward('ad-2', 'correction'), 'capped',
  'au plus une correction offerte par jour');
select is(pg_temp.reward('ad-3', 'exercises'), 'applied', 'une vidéo vue rapporte 3 exercices');
select is(pg_temp.reward('ad-4', 'exercises'), 'capped',
  'au plus 3 exercices offerts par jour');
select is(pg_temp.reward('ad-5', 'correction', '00000000-0000-0000-0000-00000000000b'),
  'ignored', 'pas de récompense pendant les 14 premiers jours');

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select is(
  public.get_ad_status(),
  '{"ads_enabled": true, "correction_reward_available": false,
    "exercises_reward_available": false, "reward_corrections": 1, "reward_exercises": 3}'::jsonb,
  'l''app connaît les récompenses obtenues et disponibles'
);
select is(public.get_entitlements(current_date) ->> 'reward_corrections', '1',
  'la correction offerte apparaît dans les droits du jour');

-- ── Ordre d'utilisation : quota du jour, crédits achetés, puis récompense ───
reset role;
select is(pg_temp.reserve() ->> 'status', 'reserved', 'la correction gratuite du jour');
update public.journal_entries set corrected_text = 'Hallo.', corrected_at = now()
 where user_id = '00000000-0000-0000-0000-00000000000a' and corrected_at is null;

update public.wallets set correction_credits = 1
 where user_id = '00000000-0000-0000-0000-00000000000a';
create temporary table credit_reservation as select pg_temp.reserve() as result;
select is(
  (select source::text from public.journal_entries
    where id = (select (result ->> 'entry_id')::uuid from credit_reservation)),
  'credit', 'un crédit acheté passe avant la correction offerte');
delete from public.journal_entries
 where user_id = '00000000-0000-0000-0000-00000000000a' and corrected_at is null;
update public.wallets set correction_credits = 0
 where user_id = '00000000-0000-0000-0000-00000000000a';

create temporary table reward_reservation as select pg_temp.reserve() as result;
select is(
  (select source::text from public.journal_entries
    where id = (select (result ->> 'entry_id')::uuid from reward_reservation)),
  'reward', 'sans crédit, la correction offerte par la vidéo prend le relais');
select is(pg_temp.reserve() ->> 'reason', 'daily_limit',
  'une correction offerte déjà retenue ne sert pas deux fois');
select lives_ok(
  format($$ select public.complete_correction(%L, 'Hallo.', '[]', '[]', 'test', 1, 1) $$,
         (select result ->> 'entry_id' from reward_reservation)),
  'la correction offerte aboutit');
select is(public.ad_reward_left('00000000-0000-0000-0000-00000000000a', 'correction'), 0,
  'la correction offerte est utilisée');

-- ── Exercices offerts ───────────────────────────────────────────────────────
-- Cinq exercices : e2 à e4 faits avec la limite du jour, e1 et e5 avec la vidéo.
insert into public.exercises (id, language, category, ui_locale, question, options,
                              answer_index, explanation)
select ('00000000-0000-0000-0000-0000000000e' || n)::uuid, 'de', 'grammar', 'fr', 'Frage ' || n,
       '["a", "b", "c", "d"]', 1, 'Erklärung'
  from generate_series(1, 5) as n;
insert into public.exercise_attempts (user_id, exercise_id, attempt_date, choice, is_correct)
select '00000000-0000-0000-0000-00000000000a', ('00000000-0000-0000-0000-0000000000e' || n)::uuid,
       current_date, 1, true
  from generate_series(2, 4) as n;

select isnt(
  public.pick_exercises('00000000-0000-0000-0000-00000000000a', 'de', 'fr', current_date, 3)
    ->> 'status',
  'limit', 'limite du jour atteinte : les exercices offerts restent disponibles');

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select is(
  public.answer_exercise('00000000-0000-0000-0000-0000000000e1', 1, current_date) ->> 'left',
  '2', 'un exercice offert est utilisé');
select is(
  (public.get_ad_status() ->> 'reward_exercises'), '2', 'il reste 2 exercices offerts');
select is(
  (select row(a ->> 'status', a ->> 'left', public.get_ad_status() ->> 'reward_exercises')::text
     from public.answer_exercise('00000000-0000-0000-0000-0000000000e1', 1, current_date) as a),
  '(ok,2,2)',
  'une réponse renvoyée rend son résultat sans utiliser un autre exercice offert');
select is(
  public.answer_exercise('00000000-0000-0000-0000-0000000000e5', 1, current_date) ->> 'left',
  '1', 'un deuxième exercice offert est utilisé');

reset role;
select isnt(
  public.pick_exercises('00000000-0000-0000-0000-00000000000a', 'de', 'fr', current_date, 3)
    ->> 'status',
  'limit', 'deux exercices offerts faits : le troisième reste proposé');
set local role authenticated;

-- ── Accès ───────────────────────────────────────────────────────────────────
select throws_ok($$ select count(*) from public.ad_rewards $$, '42501', null,
  'l''app ne lit pas les récompenses directement');
select throws_ok(
  $$ select public.grant_ad_reward('ad-9', '00000000-0000-0000-0000-00000000000a', 'correction') $$,
  '42501', null, 'l''app ne peut pas s''attribuer une récompense');

select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');
select is(public.get_ad_status() ->> 'ads_enabled', 'false',
  'un nouvel inscrit ne voit pas de publicité');

select * from finish();
rollback;
