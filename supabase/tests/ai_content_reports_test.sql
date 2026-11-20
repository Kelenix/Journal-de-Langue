-- Signalement des contenus produits par l'IA (Inc-9).
-- Lancer : supabase test db
begin;
select plan(9);

insert into auth.users (id, email)
values
  ('00000000-0000-0000-0000-00000000000a', 'signale@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'autre@example.test');

insert into public.journal_entries
  (id, user_id, language, entry_date, original_text, corrected_text, sentence_count,
   idempotency_key, corrected_at)
values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-00000000000a', 'en',
   current_date, 'I has a cat.', 'I have a cat.', 1, gen_random_uuid(), now()),
  ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-00000000000b', 'en',
   current_date, 'She are nice.', 'She is nice.', 1, gen_random_uuid(), now());
insert into public.exercises (id, language, category, ui_locale, question, options,
                              answer_index, explanation)
values ('00000000-0000-0000-0000-0000000000e1', 'en', 'grammar', 'fr', 'She ___ nice.',
        '["is", "are", "be", "am"]', 0, 'Avec « she » : « is ».');

create function pg_temp.act_as(p_user uuid) returns void language sql as $$
  select set_config('request.jwt.claims',
                    json_build_object('sub', p_user, 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.act_as(uuid) to authenticated;

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');

select lives_ok(
  $$ select public.report_ai_content('correction', '00000000-0000-0000-0000-0000000000a1',
                                     '  Cette explication est fausse.  ') $$,
  'un utilisateur signale sa correction, avec un commentaire');
select lives_ok(
  $$ select public.report_ai_content('exercise', '00000000-0000-0000-0000-0000000000e1') $$,
  'et un exercice, sans commentaire');
select throws_ok(
  $$ select public.report_ai_content('correction', '00000000-0000-0000-0000-0000000000b1') $$,
  'P0002', null, 'pas la correction d''un autre utilisateur');
select throws_ok(
  $$ select public.report_ai_content('exam', '00000000-0000-0000-0000-0000000000a1') $$,
  'P0002', null, 'ni un contenu qui n''existe pas sous ce type');
select throws_ok('select * from public.ai_content_reports', '42501', null,
  'l''app ne lit pas les signalements');
reset role;

select is(
  (select array_agg(row(kind, comment)::text order by kind)
     from public.ai_content_reports
    where user_id = '00000000-0000-0000-0000-00000000000a'),
  array['(correction,"Cette explication est fausse.")', '(exercise,)'],
  'le signalement garde le type et le commentaire nettoyé');

set local role authenticated;
select pg_temp.act_as('00000000-0000-0000-0000-00000000000a');
select lives_ok(
  $$ select public.report_ai_content('exercise', '00000000-0000-0000-0000-0000000000e1')
       from generate_series(1, 18) $$,
  'jusqu''à 20 signalements par jour');
select throws_ok(
  $$ select public.report_ai_content('exercise', '00000000-0000-0000-0000-0000000000e1') $$,
  'P0001', null, 'pas un de plus');
reset role;

set local role anon;
select throws_ok(
  $$ select public.report_ai_content('exercise', '00000000-0000-0000-0000-0000000000e1') $$,
  '42501', null, 'un visiteur non connecté ne signale rien');
reset role;

select * from finish();
rollback;
