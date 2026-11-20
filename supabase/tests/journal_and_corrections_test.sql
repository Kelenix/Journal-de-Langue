-- Règles de l'incrément 2 : quota du jour, réservation, correction, accès. Lancer : supabase test db
begin;
select plan(31);

-- ── Comptage des phrases (même règle que l'app) ─────────────────────────────
select is(public.count_sentences(''), 0, 'texte vide : 0 phrase');
select is(public.count_sentences(E'  \n  '), 0, 'espaces seuls : 0 phrase');
select is(public.count_sentences('Hello'), 1, 'sans ponctuation finale : 1 phrase');
select is(public.count_sentences('One. Two! Three?'), 3, 'points, exclamation, interrogation');
select is(public.count_sentences('Wait... what?!'), 2, 'ponctuation répétée : un seul séparateur');
select is(public.count_sentences(E'Line one\nLine two\r\n\r\nLine three'), 3, 'un retour à la ligne sépare');
select is(public.count_sentences('¿Qué tal? ¡Muy bien!'), 2, 'ponctuation espagnole ouvrante ignorée');

-- ── Jeu de données ──────────────────────────────────────────────────────────
-- La base locale peut contenir d'autres données (tests d'intégration) : chaque
-- vérification faite avec le rôle propriétaire se limite aux comptes créés ici.
insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'a@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'b@example.test');
insert into public.user_languages (user_id, language)
values
  ('00000000-0000-0000-0000-00000000000a', 'en'),
  ('00000000-0000-0000-0000-00000000000b', 'en');

create function pg_temp.reserve(p_key uuid, p_text text, p_date date default current_date,
                                p_language public.language_code default 'en')
returns jsonb language sql as $$
  select public.reserve_correction(
    '00000000-0000-0000-0000-00000000000a', p_language, p_date, p_text, p_key);
$$;

-- ── Refus avant toute réservation ───────────────────────────────────────────
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000001', 'Hola.', current_date, 'es') ->> 'reason',
  'language_not_active',
  'langue non active : refusé'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000001', '   ') ->> 'reason',
  'invalid_text',
  'texte sans phrase : refusé'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000001', repeat('a', 1001)) ->> 'reason',
  'invalid_text',
  'texte au-delà de 1000 caractères : refusé'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000001', 'A. B. C. D. E. F. G. H.'),
  '{"status": "denied", "reason": "too_many_sentences", "max_sentences": 7}'::jsonb,
  '8 phrases en gratuit : refusé avec la limite'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000001', 'Hello.', current_date - 3) ->> 'reason',
  'invalid_date',
  'date trop ancienne : refusée'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000001', 'Hello.', current_date + 3) ->> 'reason',
  'invalid_date',
  'date trop lointaine : refusée'
);
select is(
  (select count(*)::int from public.journal_entries
    where user_id = '00000000-0000-0000-0000-00000000000a'),
  0,
  'un refus ne crée aucune entrée'
);

-- ── Réservation, échec, nouvelle tentative ──────────────────────────────────
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000001', 'I has a cat. She are nice.') ->> 'status',
  'reserved',
  '7 phrases ou moins : réservé'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000002', 'Another text.') ->> 'reason',
  'daily_limit',
  'correction en cours : un second texte du même jour est refusé'
);
select lives_ok(
  $$ select public.release_correction(
       (select id from public.journal_entries
         where idempotency_key = '10000000-0000-0000-0000-000000000001')) $$,
  'échec de l''IA : la réservation est annulée'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000002', 'Another text.') ->> 'status',
  'reserved',
  'après un échec, le quota du jour est de nouveau disponible'
);

-- ── Correction terminée ─────────────────────────────────────────────────────
select lives_ok(
  $$ select public.complete_correction(
       (select id from public.journal_entries
         where idempotency_key = '10000000-0000-0000-0000-000000000002'),
       'Another text, corrected.',
       '[{"original": "text", "corrected": "text, corrected", "category": "phrasing",
          "explanation": "Exemple."},
         {"original": "x", "corrected": "y", "category": "spelling", "explanation": "Exemple 2."}]'::jsonb,
       '[]'::jsonb,
       'claude-haiku-5-5', 120, 80) $$,
  'la correction est enregistrée'
);
select is(
  (select array_agg(item.original order by item.position)
     from public.correction_items as item
     join public.journal_entries as entry on entry.id = item.entry_id
    where entry.user_id = '00000000-0000-0000-0000-00000000000a'),
  array['text', 'x'],
  'les points d''erreur gardent leur ordre'
);
select is(
  (select row(feature, model, input_tokens, output_tokens)::text from public.ai_usage
    where user_id = '00000000-0000-0000-0000-00000000000a'),
  '(correction_basic,claude-haiku-5-5,120,80)',
  'le coût de l''IA est journalisé'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000002', 'Another text.'),
  jsonb_build_object(
    'status', 'corrected',
    'entry_id', (select id from public.journal_entries
                  where idempotency_key = '10000000-0000-0000-0000-000000000002')),
  'même envoi rejoué : la correction existante est rendue, sans nouveau débit'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000003', 'Third text.') ->> 'reason',
  'daily_limit',
  'une correction par jour en gratuit'
);
select is(
  pg_temp.reserve('10000000-0000-0000-0000-000000000003', 'Third text.', current_date - 1) ->> 'reason',
  'invalid_date',
  'impossible de revenir à la veille pour obtenir une autre correction'
);
select throws_ok(
  $$ select public.complete_correction(gen_random_uuid(), 'x', '[]'::jsonb, '[]'::jsonb, 'm', 1, 1) $$,
  'P0002', null,
  'terminer une réservation inexistante échoue'
);

-- ── Accès depuis l'app ──────────────────────────────────────────────────────
set local role authenticated;
set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}';

select is(
  (select row(count(*), min(corrected_text))::text from public.journal_entries),
  '(1,"Another text, corrected.")',
  'A lit son journal corrigé'
);
select is(
  public.get_entitlements(current_date),
  '{"plan": null, "max_sentences": 7, "max_characters": 1000, "corrections_left": 0, "credits": 0, "reward_corrections": 0}'::jsonb,
  'A voit ses limites et qu''il ne lui reste aucune correction aujourd''hui'
);
select throws_ok(
  $$ select public.reserve_correction(
       '00000000-0000-0000-0000-00000000000a', 'en', current_date, 'Hi.', gen_random_uuid()) $$,
  '42501', null,
  'l''app ne peut pas réserver une correction sans passer par le serveur'
);
select throws_ok(
  $$ update public.journal_entries set corrected_text = 'triche' $$,
  '42501', null,
  'l''app ne peut pas modifier un journal'
);

set local request.jwt.claims = '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}';

select is(
  (select count(*)::int from public.journal_entries)
    + (select count(*)::int from public.correction_items),
  0,
  'B ne voit ni les journaux ni les corrections de A'
);
select is(
  (public.get_entitlements(current_date) ->> 'corrections_left')::int,
  1,
  'B dispose de sa correction du jour'
);

select * from finish();
rollback;
