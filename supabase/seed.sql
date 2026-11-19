-- Données de démonstration pour le développement LOCAL uniquement.
-- Appliquées par `supabase db reset` ; jamais envoyées en production (`supabase db push`
-- ne joue pas ce fichier).
--
-- Compte de démonstration : demo@journal.test / demo-journal-2026
-- Il apprend l'anglais et possède trois journaux corrigés (dont un trop ancien pour l'offre
-- gratuite) et quelques mots à réviser. Sa correction du jour reste disponible.

do $$
declare
  v_user_id constant uuid := '11111111-1111-4111-8111-111111111111';
  v_email constant text := 'demo@journal.test';
  v_recent uuid;
  v_older uuid;
  v_locked uuid;
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change, email_change_token_new
  ) values (
    '00000000-0000-0000-0000-000000000000', v_user_id, 'authenticated', 'authenticated',
    v_email, extensions.crypt('demo-journal-2026', extensions.gen_salt('bf')), now(),
    '{"provider": "email", "providers": ["email"]}', '{}', now() - interval '30 days', now(),
    '', '', '', ''
  );

  insert into auth.identities (
    id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), v_user_id, v_user_id::text, 'email',
    jsonb_build_object('sub', v_user_id::text, 'email', v_email, 'email_verified', true),
    now(), now(), now()
  );

  -- Le profil est créé par le trigger on_auth_user_created.
  insert into public.user_languages (user_id, language) values (v_user_id, 'en');

  insert into public.journal_entries
    (user_id, language, entry_date, original_text, corrected_text, sentence_count,
     idempotency_key, corrected_at)
  values
    (v_user_id, 'en', current_date - 1,
     'Yesterday I have went to the grocery store. I buyed some apples and breads.',
     'Yesterday I went to the grocery store. I bought some apples and bread.',
     2, gen_random_uuid(), now() - interval '1 day')
  returning id into v_recent;

  insert into public.journal_entries
    (user_id, language, entry_date, original_text, corrected_text, sentence_count,
     idempotency_key, corrected_at)
  values
    (v_user_id, 'en', current_date - 2,
     'My sister is very nice. She lives in a small flat near the river.',
     'My sister is very nice. She lives in a small flat near the river.',
     2, gen_random_uuid(), now() - interval '2 days')
  returning id into v_older;

  insert into public.journal_entries
    (user_id, language, entry_date, original_text, corrected_text, sentence_count,
     idempotency_key, corrected_at)
  values
    (v_user_id, 'en', current_date - 12,
     'I am learn English since two months.',
     'I have been learning English for two months.',
     1, gen_random_uuid(), now() - interval '12 days')
  returning id into v_locked;

  insert into public.correction_items
    (entry_id, position, original, corrected, category, explanation)
  values
    (v_recent, 1, 'have went', 'went', 'conjugation',
     'Pour une action terminée hier, on emploie le prétérit : « went ».'),
    (v_recent, 2, 'buyed', 'bought', 'conjugation',
     '« To buy » est irrégulier : son prétérit est « bought ».'),
    (v_recent, 3, 'breads', 'bread', 'grammar',
     '« Bread » est indénombrable : il ne prend pas de « s ».'),
    (v_locked, 1, 'am learn', 'have been learning', 'conjugation',
     'Une action commencée dans le passé et qui continue se dit au present perfect continu.'),
    (v_locked, 2, 'since two months', 'for two months', 'grammar',
     '« For » s''emploie avec une durée, « since » avec un point de départ.');

  insert into public.vocabulary_items
    (user_id, entry_id, language, term, translation, example, learned_at, created_at)
  values
    (v_user_id, v_recent, 'en', 'a grocery store', 'une épicerie',
     'There is a grocery store on the corner.', null, now() - interval '1 day'),
    (v_user_id, v_recent, 'en', 'to buy', 'acheter',
     'She buys fresh vegetables every week.', null, now() - interval '1 day'),
    (v_user_id, v_recent, 'en', 'bread', 'du pain',
     'We need some bread for breakfast.', null, now() - interval '1 day'),
    (v_user_id, v_older, 'en', 'a flat', 'un appartement',
     'Their flat has two bedrooms.', now() - interval '1 day', now() - interval '2 days'),
    (v_user_id, v_older, 'en', 'near', 'près de',
     'The school is near the park.', null, now() - interval '2 days');
end;
$$;
