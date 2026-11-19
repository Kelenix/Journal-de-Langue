-- Inc-5 : IA Premium — corrections avancées, reformulations, exercices (US-12 à US-14).

-- ── Niveau de correction ────────────────────────────────────────────────────
create type public.correction_level as enum ('basic', 'advanced');

alter table public.journal_entries
  add column level public.correction_level not null default 'basic';

-- ── Reformulations (Premium) ────────────────────────────────────────────────
-- Conservées : redemander la même phrase ne refait pas appel à l'IA.
create table public.sentence_rewrites (
  id uuid primary key default gen_random_uuid(),
  entry_id uuid not null references public.journal_entries (id) on delete cascade,
  sentence text not null,
  polite text not null,
  casual text not null,
  professional text not null,
  created_at timestamptz not null default now()
);

create unique index sentence_rewrites_entry_sentence_idx
  on public.sentence_rewrites (entry_id, md5(sentence));

-- ── Exercices ───────────────────────────────────────────────────────────────
-- Réserve partagée entre utilisateurs, par langue, type d'erreur et langue d'interface :
-- un exercice généré une fois sert à tous (INTAKE §8.3).
create table public.exercises (
  id uuid primary key default gen_random_uuid(),
  language public.language_code not null,
  category public.error_category not null,
  ui_locale text not null check (ui_locale in ('fr', 'en')),
  question text not null,
  options jsonb not null check (jsonb_array_length(options) = 4),
  answer_index smallint not null check (answer_index between 0 and 3),
  explanation text not null,
  created_at timestamptz not null default now()
);

create index exercises_pool_idx on public.exercises (language, category, ui_locale);

create table public.exercise_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  exercise_id uuid not null references public.exercises (id) on delete cascade,
  attempt_date date not null,
  choice smallint not null,
  is_correct boolean not null,
  created_at timestamptz not null default now()
);

create index exercise_attempts_user_date_idx
  on public.exercise_attempts (user_id, attempt_date);

alter table public.sentence_rewrites enable row level security;
alter table public.exercises enable row level security;
alter table public.exercise_attempts enable row level security;

-- Reformulations et exercices sont servis par les Edge Functions ; l'app ne lit
-- directement que ses propres réponses (statistiques).
revoke all on table public.sentence_rewrites, public.exercises, public.exercise_attempts
  from anon, authenticated;
grant select on table public.exercise_attempts to authenticated;
grant all on table public.sentence_rewrites, public.exercises, public.exercise_attempts
  to service_role;

create policy exercise_attempts_select_own on public.exercise_attempts
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- ── Limites selon l'offre, complétées ───────────────────────────────────────
-- Exercices : 3 par jour en gratuit, 20 en Premium. Reformulations : Premium uniquement,
-- 30 par jour.
drop function public.plan_limits(uuid);

create function public.plan_limits(p_user_id uuid)
returns table (
  plan public.plan,
  max_sentences integer,
  max_characters integer,
  daily_corrections integer,
  daily_vocabulary integer,
  history_days integer,
  daily_exercises integer,
  daily_rewrites integer
)
language sql
stable
set search_path = ''
as $$
  select active.plan,
         case when active.plan is null then 7 else 40 end,
         case when active.plan is null then 1000 else 6000 end,
         case when active.plan is null then 1 else 30 end,
         case when active.plan is null then 5 end,
         case when active.plan is null then 4 end,
         case when active.plan is null then 3 else 20 end,
         case when active.plan is null then 0 else 30 end
    from (
      select (
        select subscription.plan
          from public.subscriptions as subscription
         where subscription.user_id = p_user_id
           and subscription.expires_at > now()
      ) as plan
    ) as active;
$$;

-- Une date fournie par l'appareil est plausible si c'est « aujourd'hui » dans au moins un
-- fuseau horaire (UTC-12 à UTC+14).
create function public.is_plausible_local_date(p_date date)
returns boolean
language sql
stable
set search_path = ''
as $$
  select p_date between (now() at time zone 'Etc/GMT+12')::date
                    and (now() at time zone 'Etc/GMT-14')::date;
$$;

-- ── Correction : le niveau dépend de l'offre au moment de l'envoi ────────────
create or replace function public.reserve_correction(
  p_user_id uuid,
  p_language public.language_code,
  p_entry_date date,
  p_text text,
  p_idempotency_key uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limits record;
  v_entry_id uuid;
  v_sentence_count integer;
  v_level public.correction_level;
begin
  -- Sérialise les demandes d'un même utilisateur : deux envois simultanés ne peuvent pas
  -- dépasser le quota.
  perform 1 from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'unknown_user' using errcode = 'P0002';
  end if;

  -- Même envoi rejoué après une coupure réseau : on rend la correction déjà faite.
  select id into v_entry_id
    from public.journal_entries
   where user_id = p_user_id
     and idempotency_key = p_idempotency_key
     and corrected_at is not null;
  if found then
    return jsonb_build_object('status', 'corrected', 'entry_id', v_entry_id);
  end if;

  -- Une réservation jamais terminée (nouvelle tentative ou abandon) ne bloque pas le quota.
  delete from public.journal_entries
   where user_id = p_user_id
     and corrected_at is null
     and (idempotency_key = p_idempotency_key or created_at < now() - interval '2 minutes');

  if not exists (
    select 1 from public.user_languages
     where user_id = p_user_id and language = p_language and is_active
  ) then
    return jsonb_build_object('status', 'denied', 'reason', 'language_not_active');
  end if;

  -- La date ne peut pas non plus reculer par rapport au dernier journal.
  if not public.is_plausible_local_date(p_entry_date)
     or exists (
       select 1 from public.journal_entries
        where user_id = p_user_id and entry_date > p_entry_date
     ) then
    return jsonb_build_object('status', 'denied', 'reason', 'invalid_date');
  end if;

  select * into v_limits from public.plan_limits(p_user_id);
  v_sentence_count := public.count_sentences(p_text);

  if v_sentence_count = 0 or char_length(p_text) > v_limits.max_characters then
    return jsonb_build_object(
      'status', 'denied',
      'reason', 'invalid_text',
      'max_characters', v_limits.max_characters
    );
  end if;

  if v_sentence_count > v_limits.max_sentences then
    return jsonb_build_object(
      'status', 'denied',
      'reason', 'too_many_sentences',
      'max_sentences', v_limits.max_sentences
    );
  end if;

  if (
    select count(*) from public.journal_entries
     where user_id = p_user_id and entry_date = p_entry_date
  ) >= v_limits.daily_corrections then
    return jsonb_build_object('status', 'denied', 'reason', 'daily_limit');
  end if;

  -- Correction avancée pour les abonnés (INTAKE §2.2).
  v_level := case when v_limits.plan is null then 'basic' else 'advanced' end;

  insert into public.journal_entries
    (user_id, language, entry_date, original_text, sentence_count, idempotency_key, level)
  values
    (p_user_id, p_language, p_entry_date, p_text, v_sentence_count, p_idempotency_key, v_level)
  returning id into v_entry_id;

  return jsonb_build_object('status', 'reserved', 'entry_id', v_entry_id, 'level', v_level);
end;
$$;

create or replace function public.complete_correction(
  p_entry_id uuid,
  p_corrected_text text,
  p_items jsonb,
  p_vocabulary jsonb,
  p_model text,
  p_input_tokens integer,
  p_output_tokens integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_entry public.journal_entries;
  v_daily_vocabulary integer;
  v_vocabulary_today integer;
begin
  update public.journal_entries
     set corrected_text = p_corrected_text,
         corrected_at = now()
   where id = p_entry_id
     and corrected_at is null
  returning * into v_entry;
  if not found then
    raise exception 'reservation_not_found' using errcode = 'P0002';
  end if;

  insert into public.correction_items
    (entry_id, position, original, corrected, category, explanation)
  select p_entry_id,
         item.position,
         item.value ->> 'original',
         item.value ->> 'corrected',
         (item.value ->> 'category')::public.error_category,
         item.value ->> 'explanation'
    from jsonb_array_elements(p_items) with ordinality as item (value, position);

  -- Vocabulaire : dans la limite quotidienne de l'offre (aucune en Premium), sans doublon.
  select daily_vocabulary into v_daily_vocabulary
    from public.plan_limits(v_entry.user_id);

  select count(*) into v_vocabulary_today
    from public.vocabulary_items as word
    join public.journal_entries as entry on entry.id = word.entry_id
   where word.user_id = v_entry.user_id
     and entry.entry_date = v_entry.entry_date;

  insert into public.vocabulary_items
    (user_id, entry_id, language, term, translation, example)
  select v_entry.user_id,
         p_entry_id,
         v_entry.language,
         btrim(word.value ->> 'term'),
         word.value ->> 'translation',
         word.value ->> 'example'
    from jsonb_array_elements(p_vocabulary) with ordinality as word (value, position)
   where btrim(word.value ->> 'term') <> ''
   order by word.position
   -- « limit null » ne limite pas.
   limit case
           when v_daily_vocabulary is null then null
           else greatest(v_daily_vocabulary - v_vocabulary_today, 0)
         end
  on conflict (user_id, language, lower(term)) do nothing;

  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
  values (
    v_entry.user_id, 'correction_' || v_entry.level, p_model, p_input_tokens, p_output_tokens
  );
end;
$$;

-- ── Reformulation ───────────────────────────────────────────────────────────
-- Retour : {status: 'cached', rewrite}, {status: 'needed', language} ou
-- {status: 'denied', reason}.
create function public.reserve_rewrite(p_user_id uuid, p_entry_id uuid, p_sentence text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_limits record;
  v_entry public.journal_entries;
  v_rewrite public.sentence_rewrites;
begin
  select * into v_limits from public.plan_limits(p_user_id);
  if v_limits.plan is null then
    return jsonb_build_object('status', 'denied', 'reason', 'premium_required');
  end if;

  -- La phrase doit venir de la version corrigée d'un journal de l'utilisateur.
  select * into v_entry
    from public.journal_entries
   where id = p_entry_id and user_id = p_user_id and corrected_at is not null;
  if not found
     or btrim(p_sentence) = ''
     or char_length(p_sentence) > 500
     or position(p_sentence in v_entry.corrected_text) = 0 then
    return jsonb_build_object('status', 'denied', 'reason', 'invalid_sentence');
  end if;

  select * into v_rewrite
    from public.sentence_rewrites
   where entry_id = p_entry_id and md5(sentence) = md5(p_sentence);
  if found then
    return jsonb_build_object('status', 'cached', 'rewrite', jsonb_build_object(
      'polite', v_rewrite.polite,
      'casual', v_rewrite.casual,
      'professional', v_rewrite.professional
    ));
  end if;

  if (
    select count(*)
      from public.sentence_rewrites as rewrite
      join public.journal_entries as entry on entry.id = rewrite.entry_id
     where entry.user_id = p_user_id
       and rewrite.created_at > now() - interval '1 day'
  ) >= v_limits.daily_rewrites then
    return jsonb_build_object('status', 'denied', 'reason', 'rewrite_limit');
  end if;

  return jsonb_build_object('status', 'needed', 'language', v_entry.language);
end;
$$;

create function public.save_rewrite(
  p_user_id uuid,
  p_entry_id uuid,
  p_sentence text,
  p_polite text,
  p_casual text,
  p_professional text,
  p_model text,
  p_input_tokens integer,
  p_output_tokens integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.sentence_rewrites (entry_id, sentence, polite, casual, professional)
  values (p_entry_id, p_sentence, p_polite, p_casual, p_professional)
  on conflict (entry_id, md5(sentence)) do nothing;

  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
  values (p_user_id, 'rewrite', p_model, p_input_tokens, p_output_tokens);
end;
$$;

-- ── Exercices ───────────────────────────────────────────────────────────────
-- Choisit les prochains exercices de l'utilisateur.
-- Premium : sur son type d'erreur le plus fréquent dans cette langue. Gratuit, ou sans
-- erreur connue : sur un type qui change chaque jour.
-- Retour : {status: 'ok', category, is_personalized, left, exercises},
-- {status: 'need_generation', category} ou {status: 'limit', is_premium}.
create function public.pick_exercises(
  p_user_id uuid,
  p_language public.language_code,
  p_ui_locale text,
  p_attempt_date date,
  p_count integer
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c_pool_target constant integer := 60;
  v_limits record;
  v_left integer;
  v_needed integer;
  v_category public.error_category;
  v_is_personalized boolean := false;
  v_exercises jsonb;
  v_pool_size integer;
begin
  if not public.is_plausible_local_date(p_attempt_date) then
    return jsonb_build_object('status', 'denied', 'reason', 'invalid_date');
  end if;

  select * into v_limits from public.plan_limits(p_user_id);
  select v_limits.daily_exercises - count(*) into v_left
    from public.exercise_attempts
   where user_id = p_user_id and attempt_date = p_attempt_date;
  if v_left <= 0 then
    return jsonb_build_object('status', 'limit', 'is_premium', v_limits.plan is not null);
  end if;
  v_needed := least(p_count, v_left);

  if v_limits.plan is not null then
    select item.category into v_category
      from public.correction_items as item
      join public.journal_entries as entry on entry.id = item.entry_id
     where entry.user_id = p_user_id and entry.language = p_language
     group by item.category
     order by count(*) desc, item.category
     limit 1;
    v_is_personalized := v_category is not null;
  end if;
  if v_category is null then
    v_category := (enum_range(null::public.error_category))[
      1 + extract(doy from p_attempt_date)::integer
          % array_length(enum_range(null::public.error_category), 1)
    ];
  end if;

  -- D'abord les exercices que l'utilisateur n'a jamais faits.
  select coalesce(jsonb_agg(to_jsonb(fresh)), '[]'::jsonb) into v_exercises
    from (
      select exercise.id, exercise.question, exercise.options
        from public.exercises as exercise
       where exercise.language = p_language
         and exercise.category = v_category
         and exercise.ui_locale = p_ui_locale
         and not exists (
           select 1 from public.exercise_attempts as attempt
            where attempt.user_id = p_user_id and attempt.exercise_id = exercise.id
         )
       order by exercise.created_at, exercise.id
       limit v_needed
    ) as fresh;

  if jsonb_array_length(v_exercises) < v_needed then
    select count(*) into v_pool_size
      from public.exercises
     where language = p_language and category = v_category and ui_locale = p_ui_locale;
    if v_pool_size < c_pool_target then
      return jsonb_build_object('status', 'need_generation', 'category', v_category);
    end if;
  end if;

  -- Réserve épuisée pour cet utilisateur : il refait les plus anciens.
  if jsonb_array_length(v_exercises) = 0 then
    select coalesce(jsonb_agg(to_jsonb(seen)), '[]'::jsonb) into v_exercises
      from (
        select exercise.id, exercise.question, exercise.options
          from public.exercises as exercise
          join public.exercise_attempts as attempt
            on attempt.exercise_id = exercise.id and attempt.user_id = p_user_id
         where exercise.language = p_language
           and exercise.category = v_category
           and exercise.ui_locale = p_ui_locale
         group by exercise.id
         order by max(attempt.created_at)
         limit v_needed
      ) as seen;
  end if;

  return jsonb_build_object(
    'status', 'ok',
    'category', v_category,
    'is_personalized', v_is_personalized,
    'left', v_left,
    'exercises', v_exercises
  );
end;
$$;

-- Ajoute à la réserve les exercices générés, en écartant ceux qui sont mal formés.
create function public.add_exercises(
  p_user_id uuid,
  p_language public.language_code,
  p_category public.error_category,
  p_ui_locale text,
  p_exercises jsonb,
  p_model text,
  p_input_tokens integer,
  p_output_tokens integer
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_added integer;
begin
  insert into public.exercises
    (language, category, ui_locale, question, options, answer_index, explanation)
  select p_language,
         p_category,
         p_ui_locale,
         generated.value ->> 'question',
         generated.value -> 'options',
         (generated.value ->> 'answer_index')::smallint,
         generated.value ->> 'explanation'
    from jsonb_array_elements(p_exercises) as generated (value)
   where btrim(generated.value ->> 'question') <> ''
     and jsonb_typeof(generated.value -> 'options') = 'array'
     and jsonb_array_length(generated.value -> 'options') = 4
     and (generated.value ->> 'answer_index')::integer between 0 and 3;
  get diagnostics v_added = row_count;

  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
  values (p_user_id, 'exercises', p_model, p_input_tokens, p_output_tokens);

  return v_added;
end;
$$;

-- Enregistre la réponse de l'utilisateur connecté et rend la correction de l'exercice.
-- Retour : {status: 'ok', is_correct, answer_index, explanation, left} ou
-- {status: 'limit'} / {status: 'denied', reason}.
create function public.answer_exercise(
  p_exercise_id uuid,
  p_choice integer,
  p_attempt_date date
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_exercise public.exercises;
  v_daily integer;
  v_done integer;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;
  if not public.is_plausible_local_date(p_attempt_date) then
    return jsonb_build_object('status', 'denied', 'reason', 'invalid_date');
  end if;

  select * into v_exercise from public.exercises where id = p_exercise_id;
  if not found or p_choice not between 0 and 3 then
    return jsonb_build_object('status', 'denied', 'reason', 'invalid_answer');
  end if;

  -- Sérialise les réponses d'un même utilisateur : la limite du jour ne peut pas être
  -- dépassée par deux envois simultanés.
  perform 1 from public.profiles where id = v_user_id for update;

  select daily_exercises into v_daily from public.plan_limits(v_user_id);
  select count(*) into v_done
    from public.exercise_attempts
   where user_id = v_user_id and attempt_date = p_attempt_date;
  if v_done >= v_daily then
    return jsonb_build_object('status', 'limit');
  end if;

  insert into public.exercise_attempts (user_id, exercise_id, attempt_date, choice, is_correct)
  values (
    v_user_id, p_exercise_id, p_attempt_date, p_choice, p_choice = v_exercise.answer_index
  );

  return jsonb_build_object(
    'status', 'ok',
    'is_correct', p_choice = v_exercise.answer_index,
    'answer_index', v_exercise.answer_index,
    'explanation', v_exercise.explanation,
    'left', v_daily - v_done - 1
  );
end;
$$;

revoke execute on function
  public.plan_limits(uuid),
  public.is_plausible_local_date(date),
  public.reserve_rewrite(uuid, uuid, text),
  public.save_rewrite(uuid, uuid, text, text, text, text, text, integer, integer),
  public.pick_exercises(uuid, public.language_code, text, date, integer),
  public.add_exercises(
    uuid, public.language_code, public.error_category, text, jsonb, text, integer, integer),
  public.answer_exercise(uuid, integer, date)
from public, anon, authenticated;

grant execute on function
  public.reserve_rewrite(uuid, uuid, text),
  public.save_rewrite(uuid, uuid, text, text, text, text, text, integer, integer),
  public.pick_exercises(uuid, public.language_code, text, date, integer),
  public.add_exercises(
    uuid, public.language_code, public.error_category, text, jsonb, text, integer, integer)
to service_role;

grant execute on function public.answer_exercise(uuid, integer, date) to authenticated;
