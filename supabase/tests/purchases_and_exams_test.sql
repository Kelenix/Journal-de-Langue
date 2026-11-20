-- Règles de l'incrément 7 : achats uniques, crédits, accès langue, simulation d'examen.
-- Lancer : supabase test db
begin;
select plan(46);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'acheteur@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'autre@example.test');
insert into public.user_languages (user_id, language)
values
  ('00000000-0000-0000-0000-00000000000a', 'en'),
  ('00000000-0000-0000-0000-00000000000b', 'en');

create function pg_temp.act_as(p_user uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
                    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.act_as(uuid) to authenticated;

-- Notification d'achat unique (ou de remboursement) pour l'acheteur.
create function pg_temp.store_event(
  p_event_id text, p_type text, p_product_id text, p_transaction_id text,
  p_quantity integer default 1, p_cancel_reason text default null
) returns text language sql as $$
  select public.apply_store_event(
    p_event_id, '00000000-0000-0000-0000-00000000000a', p_type, p_product_id, null, false,
    now(), p_transaction_id, p_quantity, p_cancel_reason);
$$;

create function pg_temp.credits() returns integer language sql as $$
  select correction_credits from public.wallets
   where user_id = '00000000-0000-0000-0000-00000000000a';
$$;

create function pg_temp.reserve(p_language public.language_code, p_text text default 'Hello.')
returns jsonb language sql as $$
  select public.reserve_correction(
    '00000000-0000-0000-0000-00000000000a', p_language, current_date, p_text, gen_random_uuid());
$$;

-- ── Achats uniques et remboursements ────────────────────────────────────────
select is(pg_temp.store_event('ev-1', 'NON_RENEWING_PURCHASE', 'corrections_10', 'tx-1'),
  'applied', 'un pack de 10 corrections est appliqué');
select is(pg_temp.credits(), 10, 'le solde augmente de 10');
select is(pg_temp.store_event('ev-1', 'NON_RENEWING_PURCHASE', 'corrections_10', 'tx-1'),
  'duplicate', 'la même notification reçue deux fois n''est comptée qu''une fois');
select is(pg_temp.store_event('ev-1-bis', 'NON_RENEWING_PURCHASE', 'corrections_10', 'tx-1'),
  'duplicate', 'le même achat sous une autre notification n''est compté qu''une fois');
select is(pg_temp.store_event('ev-2', 'NON_RENEWING_PURCHASE', 'corrections_50', 'tx-2', 2),
  'applied', 'deux packs de 50 achetés ensemble');
select is(pg_temp.credits(), 110, 'la quantité est prise en compte');
select is(
  pg_temp.store_event('ev-3', 'CANCELLATION', 'corrections_10', 'tx-1', 1, 'CUSTOMER_SUPPORT'),
  'applied', 'un remboursement est appliqué');
select is(pg_temp.credits(), 100, 'un achat remboursé est repris');
select is(
  pg_temp.store_event('ev-4', 'CANCELLATION', 'corrections_10', 'tx-1', 1, 'CUSTOMER_SUPPORT'),
  'ignored', 'un achat n''est repris qu''une fois');
select is(pg_temp.store_event('ev-5', 'NON_RENEWING_PURCHASE', 'exam_pack', 'tx-5'),
  'applied', 'un Pack Examinateur est appliqué');
select is(pg_temp.store_event('ev-6', 'NON_RENEWING_PURCHASE', 'remove_ads', 'tx-6'),
  'applied', 'l''achat sans publicité est appliqué');
select is(
  (select ads_removed from public.wallets where user_id = '00000000-0000-0000-0000-00000000000a'),
  true, 'les publicités sont retirées');
select is(
  pg_temp.store_event('ev-7', 'CANCELLATION', 'remove_ads', 'tx-6', 1, 'CUSTOMER_SUPPORT'),
  'applied', 'le remboursement de « sans publicité » est appliqué');
select is(
  (select ads_removed from public.wallets where user_id = '00000000-0000-0000-0000-00000000000a'),
  false, 'un achat « sans publicité » remboursé est repris');
select is(
  public.apply_store_event('ev-8', '00000000-0000-0000-0000-00000000000a', 'INITIAL_PURCHASE',
    'premium_monthly:monthly', now() + interval '1 day', false, now(), 'tx-8', 1, null),
  'applied', 'les abonnements passent toujours par leur propre règle');
delete from public.subscriptions where user_id = '00000000-0000-0000-0000-00000000000a';

-- ── Accès à une langue pendant 30 jours ─────────────────────────────────────
select pg_temp.store_event('ev-9', 'NON_RENEWING_PURCHASE', 'language_pass_es', 'tx-9');
select ok(
  (select expires_at between now() + interval '29 days 23 hours' and now() + interval '30 days 1 hour'
     from public.language_passes
    where user_id = '00000000-0000-0000-0000-00000000000a' and language = 'es'),
  'l''accès dure 30 jours');

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select is(public.get_languages(), '{es,en}'::public.language_code[],
  'gratuit : la langue débloquée s''ajoute à la langue de l''offre et devient la langue en cours');
select lives_ok($$ select public.activate_language('de') $$, 'gratuit : choisit l''allemand');
select is(public.get_languages(), '{de,es}'::public.language_code[],
  'la nouvelle langue remplace celle de l''offre, pas la langue débloquée');
select is(public.get_wallet() -> 'language_passes' -> 0 ->> 'language', 'es',
  'l''accès en cours est visible dans les achats');

reset role;
select pg_temp.store_event('ev-10', 'NON_RENEWING_PURCHASE', 'language_pass_es', 'tx-10');
select ok(
  (select expires_at > now() + interval '59 days'
     from public.language_passes
    where user_id = '00000000-0000-0000-0000-00000000000a' and language = 'es'),
  'un second achat prolonge l''accès');

update public.language_passes set expires_at = now() - interval '1 second'
 where user_id = '00000000-0000-0000-0000-00000000000a';
select is(
  array(select language from public.usable_languages('00000000-0000-0000-0000-00000000000a')),
  '{de}'::public.language_code[],
  'au 31e jour, la langue se verrouille');
select is(pg_temp.reserve('es') ->> 'reason', 'language_not_active',
  'plus de correction dans une langue dont l''accès a expiré');

-- ── Crédits de correction ───────────────────────────────────────────────────
update public.wallets set correction_credits = 1
 where user_id = '00000000-0000-0000-0000-00000000000a';
select is(pg_temp.reserve('de') ->> 'status', 'reserved', 'la correction gratuite du jour');
update public.journal_entries set corrected_text = 'Hello.', corrected_at = now()
 where user_id = '00000000-0000-0000-0000-00000000000a' and corrected_at is null;

create temporary table credit_reservation as select pg_temp.reserve('de') as result;
select is((select result ->> 'status' from credit_reservation), 'reserved',
  'quota du jour utilisé : un crédit prend le relais');
select is(
  (select source::text from public.journal_entries
    where id = (select (result ->> 'entry_id')::uuid from credit_reservation)),
  'credit', 'la correction est rattachée au crédit');
select is(pg_temp.reserve('de') ->> 'reason', 'daily_limit',
  'un crédit déjà retenu par une correction en cours ne sert pas deux fois');
select is(pg_temp.credits(), 1, 'le crédit n''est pas débité avant la réussite');
select lives_ok(
  format($$ select public.complete_correction(%L, 'Hello.', '[]', '[]', 'test', 1, 1) $$,
         (select result ->> 'entry_id' from credit_reservation)),
  'la correction payée par un crédit aboutit');
select is(pg_temp.credits(), 0, 'exactement un crédit est débité');

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select is(public.get_entitlements(current_date) ->> 'corrections_left', '0',
  'le quota de l''offre ne compte que ses propres corrections');
select is(public.get_entitlements(current_date) ->> 'credits', '0',
  'les crédits restants sont donnés à part');

-- ── Simulation d'examen ─────────────────────────────────────────────────────
reset role;
create temporary table exam_start as
  select public.reserve_exam('00000000-0000-0000-0000-00000000000a', 'de', 'B1', 'fr') as result;
grant select on exam_start to authenticated;
select is((select result ->> 'status' from exam_start), 'preparing',
  'un Pack Examinateur permet de commencer une simulation');
select is(
  (select exam_credits from public.wallets
    where user_id = '00000000-0000-0000-0000-00000000000a'),
  0, 'le pack est utilisé');
select is(
  public.reserve_exam('00000000-0000-0000-0000-00000000000a', 'de', 'B1', 'fr') ->> 'status',
  'busy', 'pas de seconde simulation pendant la préparation du sujet');

select public.start_exam((select (result ->> 'exam_id')::uuid from exam_start),
  '{"title": "Ein Brief", "task": "Schreiben Sie.", "min_words": 120, "max_words": 180}',
  'test', 1, 1);
select is(
  public.reserve_exam('00000000-0000-0000-0000-00000000000a', 'de', 'C1', 'fr'),
  jsonb_build_object('status', 'open', 'exam_id', (select result ->> 'exam_id' from exam_start)),
  'une simulation interrompue reste disponible, sans nouveau débit');

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select lives_ok(
  format($$ select public.save_exam_draft(%L, 'Ich schreibe einen') $$,
         (select result ->> 'exam_id' from exam_start)),
  'le brouillon de la rédaction est enregistré');
select is((select answer from public.exams), 'Ich schreibe einen',
  'une simulation interrompue garde le texte déjà écrit');
reset role;

select is(
  public.claim_exam_grading('00000000-0000-0000-0000-00000000000a',
    (select (result ->> 'exam_id')::uuid from exam_start), '  ') ->> 'reason',
  'invalid_text', 'une rédaction vide n''est pas corrigée');
select is(
  public.claim_exam_grading('00000000-0000-0000-0000-00000000000b',
    (select (result ->> 'exam_id')::uuid from exam_start), 'Ich schreibe.') ->> 'reason',
  'exam_not_found', 'la simulation d''un autre utilisateur est introuvable');
select is(
  public.claim_exam_grading('00000000-0000-0000-0000-00000000000a',
    (select (result ->> 'exam_id')::uuid from exam_start), 'Ich schreibe.') ->> 'status',
  'claimed', 'la rédaction est prise pour correction');
select is(
  public.claim_exam_grading('00000000-0000-0000-0000-00000000000a',
    (select (result ->> 'exam_id')::uuid from exam_start), 'Ich schreibe.') ->> 'status',
  'busy', 'une rédaction en cours de correction ne repart pas une seconde fois');

select public.complete_exam((select (result ->> 'exam_id')::uuid from exam_start),
  '{"score": 14}', 'test', 1, 1);
select is(
  (select array_agg(feature order by feature) from public.ai_usage
    where user_id = '00000000-0000-0000-0000-00000000000a' and feature like 'exam%'),
  '{exam_grading,exam_topic}'::text[],
  'le coût du sujet et de la correction est journalisé');

-- Sujet impossible à créer : le pack est rendu.
update public.wallets set exam_credits = 1
 where user_id = '00000000-0000-0000-0000-00000000000a';
select public.release_exam((public.reserve_exam(
  '00000000-0000-0000-0000-00000000000a', 'de', 'A2', 'en') ->> 'exam_id')::uuid);
select is(
  (select exam_credits from public.wallets
    where user_id = '00000000-0000-0000-0000-00000000000a'),
  1, 'un sujet qui n''a pas pu être créé rend le pack');

-- ── Accès ───────────────────────────────────────────────────────────────────
set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000b');
select is((select count(*)::int from public.exams), 0,
  'un utilisateur ne voit pas les simulations d''un autre');
select throws_ok($$ select public.reserve_exam(
    '00000000-0000-0000-0000-00000000000b', 'en', 'B1', 'fr') $$,
  '42501', null, 'l''app ne peut pas débiter un pack elle-même');

select * from finish();
rollback;
