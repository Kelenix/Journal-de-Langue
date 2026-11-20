-- Règles de l'incrément 4 : abonnement, limites selon l'offre. Lancer : supabase test db
begin;
select plan(27);

-- La base locale peut contenir d'autres données : chaque vérification faite avec le rôle
-- propriétaire se limite aux comptes créés ici.
insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'a@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@example.test');
insert into public.user_languages (user_id, language)
values ('00000000-0000-0000-0000-00000000000a', 'en');

-- Un journal ancien et corrigé pour A.
insert into public.journal_entries
  (user_id, language, entry_date, original_text, corrected_text, sentence_count,
   idempotency_key, corrected_at)
values
  ('00000000-0000-0000-0000-00000000000a', 'en', current_date - 30, 'Old.', 'Old.', 1,
   gen_random_uuid(), now() - interval '30 days');

create function pg_temp.event(p_id text, p_type text, p_product text, p_expires timestamptz,
                              p_event_at timestamptz, p_trial boolean default false,
                              p_user uuid default '00000000-0000-0000-0000-00000000000a')
returns text language sql as $$
  select public.apply_subscription_event(
    p_id, p_user, p_type, p_product, p_expires, p_trial, p_event_at);
$$;

create function pg_temp.limits_of_a() returns text language sql as $$
  select row(plan, max_sentences, daily_corrections, daily_vocabulary, history_days)::text
    from public.plan_limits('00000000-0000-0000-0000-00000000000a');
$$;

create function pg_temp.reserve(p_text text) returns jsonb language sql as $$
  select public.reserve_correction(
    '00000000-0000-0000-0000-00000000000a', 'en', current_date, p_text, gen_random_uuid());
$$;

-- ── Identifiants de produits ────────────────────────────────────────────────
select is(public.plan_of_product('premium_annual')::text, 'annual', 'produit App Store');
select is(public.plan_of_product('premium_monthly:monthly-base')::text, 'monthly',
          'produit Google Play « abonnement:offre de base »');
select is(public.plan_of_product('pack_10_corrections')::text, null, 'produit hors abonnement');

-- ── Sans abonnement ─────────────────────────────────────────────────────────
select is(pg_temp.limits_of_a(), '(,7,1,5,4)', 'sans abonnement : limites gratuites');

-- ── Essai puis abonnement ───────────────────────────────────────────────────
select is(
  pg_temp.event('evt-1', 'INITIAL_PURCHASE', 'premium_annual:annual-base',
                now() + interval '3 days', now() - interval '1 minute', true),
  'applied',
  'un essai gratuit est appliqué'
);
select is(
  (select row(plan, in_trial, expires_at > now())::text from public.subscriptions
    where user_id = '00000000-0000-0000-0000-00000000000a'),
  '(annual,t,t)',
  'A est en essai Premium annuel'
);
select is(pg_temp.limits_of_a(), '(annual,40,30,,)',
          'Premium : 40 phrases, 30 corrections par jour, vocabulaire et historique sans limite');
select is(
  pg_temp.event('evt-1', 'INITIAL_PURCHASE', 'premium_annual:annual-base',
                now() + interval '300 days', now(), false),
  'duplicate',
  'la même notification rejouée n''est pas réappliquée'
);
select is(
  pg_temp.event('evt-2', 'RENEWAL', 'premium_annual:annual-base',
                now() + interval '368 days', now(), false),
  'applied',
  'le renouvellement prolonge l''abonnement'
);
select is(
  (select row(in_trial, expires_at > now() + interval '300 days')::text from public.subscriptions
    where user_id = '00000000-0000-0000-0000-00000000000a'),
  '(f,t)',
  'l''essai est terminé, l''échéance repoussée'
);
select is(
  pg_temp.event('evt-0', 'INITIAL_PURCHASE', 'premium_weekly',
                now() - interval '1 day', now() - interval '10 days', false),
  'stale',
  'une notification plus ancienne arrivée en retard n''écrase pas l''état'
);

-- ── Effets de Premium ───────────────────────────────────────────────────────
select is(
  pg_temp.reserve('One. Two. Three. Four. Five. Six. Seven. Eight.') ->> 'status',
  'reserved',
  'Premium : un journal de 8 phrases est accepté'
);
select is(
  pg_temp.reserve('A second entry the same day.') ->> 'status',
  'reserved',
  'Premium : plusieurs journaux le même jour'
);
select lives_ok(
  $$ select public.complete_correction(
       (select id from public.journal_entries
         where user_id = '00000000-0000-0000-0000-00000000000a'
           and original_text = 'A second entry the same day.'),
       'A second entry the same day.', '[]'::jsonb,
       (select jsonb_agg(jsonb_build_object('term', 'word ' || n, 'translation', 't', 'example', 'e'))
          from generate_series(1, 8) as n),
       'claude-haiku-5-5', 10, 10) $$,
  'une correction Premium propose 8 mots'
);
select is(
  (select count(*)::int from public.vocabulary_items
    where user_id = '00000000-0000-0000-0000-00000000000a'),
  8,
  'Premium : pas de limite quotidienne de vocabulaire'
);

set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

select is(
  (select count(*)::int from public.journal_entries where entry_date = current_date - 30),
  1,
  'Premium : A relit son journal ancien'
);
select is(
  public.get_history_overview(),
  '{"history_days": null, "locked_entries": 0, "corrected_entries": 2}'::jsonb,
  'Premium : rien n''est verrouillé'
);
select is(
  public.get_entitlements(current_date) - 'corrections_left',
  '{"plan": "annual", "max_sentences": 40, "max_characters": 6000, "credits": 0, "reward_corrections": 0}'::jsonb,
  'A voit son offre et ses limites Premium'
);
select is(
  (select plan::text from public.subscriptions),
  'annual',
  'A lit son abonnement'
);
select throws_ok(
  $$ update public.subscriptions set expires_at = now() + interval '10 years' $$,
  '42501', null,
  'A ne peut pas prolonger son abonnement lui-même'
);
select throws_ok(
  $$ select public.apply_subscription_event(
       'evt-x', '00000000-0000-0000-0000-00000000000a', 'RENEWAL', 'premium_annual',
       now() + interval '10 years', false, now()) $$,
  '42501', null,
  'A ne peut pas s''attribuer un abonnement'
);

set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';
select is((select count(*)::int from public.subscriptions), 0, 'B ne voit pas l''abonnement de A');
select is(
  public.get_entitlements(current_date) ->> 'plan', null, 'B reste sur l''offre gratuite');

reset role;

-- ── Fin de l'abonnement ─────────────────────────────────────────────────────
select is(
  pg_temp.event('evt-3', 'EXPIRATION', 'premium_annual:annual-base',
                now() - interval '1 minute', now() + interval '1 minute', false),
  'applied',
  'l''expiration est appliquée'
);
select is(pg_temp.limits_of_a(), '(,7,1,5,4)', 'abonnement expiré : retour aux limites gratuites');

-- ── Notifications sans effet ────────────────────────────────────────────────
select is(
  pg_temp.event('evt-4', 'NON_RENEWING_PURCHASE', 'pack_10_corrections', null,
                now() + interval '2 minutes', false),
  'ignored',
  'un produit hors abonnement est enregistré sans toucher à l''abonnement'
);
select is(
  pg_temp.event('evt-5', 'INITIAL_PURCHASE', 'premium_monthly', now() + interval '30 days',
                now(), false, '99999999-9999-4999-8999-999999999999'),
  'ignored',
  'une notification pour un utilisateur inconnu est ignorée sans erreur'
);

select * from finish();
rollback;
