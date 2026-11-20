-- Phase 5 (revue du serveur, ADR-041) : envois rejoués, tentatives qui rendent le quota,
-- exercices offerts, abonnements dans le désordre, index manquants.

-- ── Appels à Claude sans résultat enregistré ────────────────────────────────
-- Refus, mauvaise langue ou résultat non enregistré : Claude a répondu (et coûté), mais le
-- quota est rendu. Les compter permet de plafonner ces tentatives. Les pannes de l'API ne
-- sont pas comptées : une panne générale ne doit bloquer personne.
alter table public.ai_usage add column succeeded boolean not null default true;

create function public.failed_ai_calls(p_user_id uuid, p_feature_pattern text)
returns integer
language sql
stable
set search_path = ''
as $$
  select count(*)::integer
    from public.ai_usage as usage
   where usage.user_id = p_user_id
     and not usage.succeeded
     and usage.feature like p_feature_pattern
     and usage.created_at > now() - interval '1 day';
$$;

-- ── Fenêtre d'historique d'un utilisateur donné ─────────────────────────────
-- Même règle que la RLS, utilisable par les fonctions du serveur (rôle service).
create function public.history_start_date(p_user_id uuid)
returns date
language sql
stable
set search_path = ''
as $$
  select case
           when limits.history_days is null then '-infinity'::date
           else (now() at time zone 'Etc/GMT+12')::date - (limits.history_days - 1)
         end
    from public.plan_limits(p_user_id) as limits;
$$;

create or replace function public.history_start_date()
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select public.history_start_date((select auth.uid()));
$$;

-- Évaluée une fois par requête, et non pour chaque journal compté.
create or replace function public.get_history_overview()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'history_days', limits.history_days,
    'locked_entries', counts.locked,
    'corrected_entries', counts.corrected
  )
  from public.plan_limits((select auth.uid())) as limits,
       lateral (
         select
           (count(*) filter (where entry.entry_date < (select public.history_start_date())))
             ::integer as locked,
           count(*)::integer as corrected
           from public.journal_entries as entry
          where entry.user_id = (select auth.uid())
            and entry.corrected_at is not null
       ) as counts;
$$;

-- ── Correction : envoi rejoué, tentatives ratées ────────────────────────────
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
  -- Au-delà, plus de tentative pendant 24 h : le quota rendu ne permet plus de boucler.
  c_max_failed_calls constant integer := 10;
  -- Plus long appel à Claude (90 s pour une correction avancée), avec de la marge.
  c_stale_after constant interval := interval '2 minutes';
  v_limits record;
  v_entry public.journal_entries;
  v_entry_id uuid;
  v_sentence_count integer;
  v_level public.correction_level;
  v_source public.correction_source;
  v_credits_left integer;
  v_rewards_left integer;
begin
  -- Sérialise les demandes d'un même utilisateur : deux envois simultanés ne peuvent pas
  -- dépasser le quota ni utiliser deux fois le même crédit.
  perform 1 from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'unknown_user' using errcode = 'P0002';
  end if;

  select * into v_entry
    from public.journal_entries
   where user_id = p_user_id and idempotency_key = p_idempotency_key;
  if found then
    if v_entry.corrected_at is not null then
      -- Même envoi rejoué après une coupure : la correction déjà faite, tant que l'offre
      -- permet de la relire (la RLS cache les plus anciennes).
      if v_entry.entry_date < public.history_start_date(p_user_id) then
        return jsonb_build_object('status', 'denied', 'reason', 'history_locked');
      end if;
      return jsonb_build_object('status', 'corrected', 'entry_id', v_entry.id);
    end if;
    -- Même envoi encore en cours de correction : un seul appel à Claude.
    if v_entry.created_at >= now() - c_stale_after then
      return jsonb_build_object('status', 'busy');
    end if;
  end if;

  -- Une réservation abandonnée (fonction arrêtée en route) ne bloque pas le quota.
  delete from public.journal_entries
   where user_id = p_user_id
     and corrected_at is null
     and created_at < now() - c_stale_after;

  if not public.is_usable_language(p_user_id, p_language) then
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

  if public.failed_ai_calls(p_user_id, 'correction_%') >= c_max_failed_calls then
    return jsonb_build_object('status', 'denied', 'reason', 'too_many_attempts');
  end if;

  if (
    select count(*) from public.journal_entries
     where user_id = p_user_id and entry_date = p_entry_date and source = 'plan'
  ) < v_limits.daily_corrections then
    v_source := 'plan';
  else
    -- Quota du jour utilisé : un crédit acheté prend le relais (hypothèse H6). Il n'est
    -- débité qu'à la réussite de la correction ; les réservations en cours le retiennent.
    select coalesce(max(wallet.correction_credits), 0) - (
             select count(*) from public.journal_entries
              where user_id = p_user_id and corrected_at is null and source = 'credit')
      into v_credits_left
      from public.wallets as wallet
     where wallet.user_id = p_user_id;
    if v_credits_left > 0 then
      v_source := 'credit';
    else
      -- Puis une correction offerte par une vidéo (hypothèse H6, US-23).
      v_rewards_left := public.ad_reward_left(p_user_id, 'correction') - (
        select count(*) from public.journal_entries
         where user_id = p_user_id and corrected_at is null and source = 'reward');
      if v_rewards_left <= 0 then
        return jsonb_build_object('status', 'denied', 'reason', 'daily_limit');
      end if;
      v_source := 'reward';
    end if;
  end if;

  -- Correction avancée pour les abonnés (INTAKE §2.2).
  v_level := case when v_limits.plan is null then 'basic' else 'advanced' end;

  insert into public.journal_entries
    (user_id, language, entry_date, original_text, sentence_count, idempotency_key, level,
     source)
  values
    (p_user_id, p_language, p_entry_date, p_text, v_sentence_count, p_idempotency_key, v_level,
     v_source)
  returning id into v_entry_id;

  return jsonb_build_object('status', 'reserved', 'entry_id', v_entry_id, 'level', v_level);
end;
$$;

-- ── Récompenses : deux utilisations simultanées prennent deux vidéos ────────
create or replace function public.use_ad_reward(p_user_id uuid, p_kind public.ad_reward_kind)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.ad_rewards
     set remaining = remaining - 1
   where transaction_id = (
     select reward.transaction_id
       from public.ad_rewards as reward
      where reward.user_id = p_user_id and reward.kind = p_kind and reward.remaining > 0
      order by reward.created_at, reward.transaction_id
      limit 1
      for update skip locked
   )
     and remaining > 0;
  return found;
end;
$$;

-- ── Exercices : les exercices offerts déjà faits ne comptent qu'une fois ────
create or replace function public.pick_exercises(
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

  if not public.is_usable_language(p_user_id, p_language) then
    return jsonb_build_object('status', 'denied', 'reason', 'language_not_active');
  end if;

  select * into v_limits from public.plan_limits(p_user_id);
  -- Les exercices offerts par une vidéo s'ajoutent à la limite du jour (US-23). Ceux déjà
  -- faits sont dans les réponses du jour et ne sont plus dans les récompenses restantes.
  select greatest(v_limits.daily_exercises - count(*), 0)
         + public.ad_reward_left(p_user_id, 'exercises')
    into v_left
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

-- ── Exercices : une réponse renvoyée après une coupure ne compte qu'une fois ─
-- Doublons laissés par des réponses renvoyées : la première est gardée.
delete from public.exercise_attempts as attempt
 using public.exercise_attempts as earlier
 where attempt.user_id = earlier.user_id
   and attempt.exercise_id = earlier.exercise_id
   and attempt.attempt_date = earlier.attempt_date
   and (attempt.created_at, attempt.id) > (earlier.created_at, earlier.id);

create unique index exercise_attempts_once_a_day_idx
  on public.exercise_attempts (user_id, exercise_id, attempt_date);

create or replace function public.answer_exercise(
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
  v_attempt public.exercise_attempts;
  v_daily integer;
  v_done integer;
  v_rewarded boolean := false;
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

  -- Réponse déjà enregistrée (la réponse du serveur s'est perdue) : elle est rendue telle
  -- quelle, sans décompter un autre exercice.
  select * into v_attempt
    from public.exercise_attempts
   where user_id = v_user_id and exercise_id = p_exercise_id and attempt_date = p_attempt_date;
  if found then
    return jsonb_build_object(
      'status', 'ok',
      'is_correct', v_attempt.is_correct,
      'answer_index', v_exercise.answer_index,
      'explanation', v_exercise.explanation,
      'left', greatest(v_daily - v_done, 0) + public.ad_reward_left(v_user_id, 'exercises')
    );
  end if;

  -- Au-delà de la limite du jour, un exercice offert par une vidéo est utilisé (US-23).
  if v_done >= v_daily then
    v_rewarded := public.use_ad_reward(v_user_id, 'exercises');
    if not v_rewarded then
      return jsonb_build_object('status', 'limit');
    end if;
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
    'left', greatest(v_daily - v_done - 1, 0)
            + public.ad_reward_left(v_user_id, 'exercises')
  );
end;
$$;

-- ── Exercices générés : un exercice mal formé est écarté, pas tout le lot ───
create or replace function public.add_exercises(
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
     -- Les types d'abord : ni longueur d'un scalaire, ni conversion d'un nombre décimal.
     and case
           when jsonb_typeof(generated.value -> 'options') = 'array'
            and jsonb_typeof(generated.value -> 'answer_index') = 'number'
           then jsonb_array_length(generated.value -> 'options') = 4
            and generated.value ->> 'answer_index' in ('0', '1', '2', '3')
           else false
         end;
  get diagnostics v_added = row_count;

  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
  values (p_user_id, 'exercises', p_model, p_input_tokens, p_output_tokens);

  return v_added;
end;
$$;

-- ── Reformulations : chaque appel à Claude compte dans la limite du jour ────
create or replace function public.reserve_rewrite(p_user_id uuid, p_entry_id uuid, p_sentence text)
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

  -- Appels à Claude des dernières 24 h, refus compris.
  if (
    select count(*) from public.ai_usage
     where user_id = p_user_id and feature = 'rewrite'
       and created_at > now() - interval '1 day'
  ) >= v_limits.daily_rewrites then
    return jsonb_build_object('status', 'denied', 'reason', 'rewrite_limit');
  end if;

  return jsonb_build_object('status', 'needed', 'language', v_entry.language);
end;
$$;

-- ── Examen : notation plus longue, tentatives ratées plafonnées ─────────────
create or replace function public.claim_exam_grading(p_user_id uuid, p_exam_id uuid, p_answer text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c_max_failed_calls constant integer := 5;
  v_exam public.exams;
begin
  perform 1 from public.profiles where id = p_user_id for update;

  select * into v_exam from public.exams where id = p_exam_id and user_id = p_user_id;
  if not found then
    return jsonb_build_object('status', 'denied', 'reason', 'exam_not_found');
  end if;
  if v_exam.status = 'graded' then
    return jsonb_build_object('status', 'graded');
  end if;
  if v_exam.status = 'preparing' then
    return jsonb_build_object('status', 'denied', 'reason', 'exam_not_found');
  end if;
  -- Une correction jamais terminée (fonction arrêtée en route) peut être relancée, passé le
  -- plus long appel à Claude (120 s).
  if v_exam.status = 'grading' and v_exam.updated_at > now() - interval '3 minutes' then
    return jsonb_build_object('status', 'busy');
  end if;
  if btrim(coalesce(p_answer, '')) = '' or char_length(p_answer) > 6000 then
    return jsonb_build_object('status', 'denied', 'reason', 'invalid_text');
  end if;
  if public.failed_ai_calls(p_user_id, 'exam_grading') >= c_max_failed_calls then
    return jsonb_build_object('status', 'denied', 'reason', 'too_many_attempts');
  end if;

  update public.exams
     set status = 'grading', answer = p_answer, updated_at = now()
   where id = p_exam_id;

  return jsonb_build_object(
    'status', 'claimed',
    'language', v_exam.language,
    'level', v_exam.level,
    'ui_locale', v_exam.ui_locale,
    'prompt', v_exam.prompt
  );
end;
$$;

-- ── Abonnements : un événement d'une autre formule ne coupe pas l'abonnement actif ─
create or replace function public.apply_subscription_event(
  p_event_id text,
  p_user_id uuid,
  p_type text,
  p_product_id text,
  p_expires_at timestamptz,
  p_in_trial boolean,
  p_event_at timestamptz
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_known_user boolean;
  v_plan public.plan := public.plan_of_product(p_product_id);
begin
  select exists (select 1 from public.profiles where id = p_user_id) into v_known_user;

  insert into public.purchase_events (event_id, user_id, type, product_id, event_at)
  values (
    p_event_id,
    case when v_known_user then p_user_id end,
    p_type,
    p_product_id,
    p_event_at
  )
  on conflict (event_id) do nothing;
  if not found then
    return 'duplicate';
  end if;

  if not v_known_user or v_plan is null or p_expires_at is null then
    return 'ignored';
  end if;

  -- Une seule ligne par utilisateur : l'expiration ou le remboursement d'une formule
  -- remplacée (ou achetée en parallèle) ne raccourcit pas l'abonnement encore actif.
  insert into public.subscriptions (user_id, plan, expires_at, in_trial, last_event_at)
  values (p_user_id, v_plan, p_expires_at, p_in_trial, p_event_at)
  on conflict (user_id) do update
    set plan = excluded.plan,
        expires_at = excluded.expires_at,
        in_trial = excluded.in_trial,
        last_event_at = excluded.last_event_at,
        updated_at = now()
    where public.subscriptions.last_event_at <= excluded.last_event_at
      and (excluded.plan = public.subscriptions.plan
           or excluded.expires_at >= public.subscriptions.expires_at
           or public.subscriptions.expires_at <= now());
  if not found then
    return 'stale';
  end if;

  return 'applied';
end;
$$;

-- ── Index et droits ─────────────────────────────────────────────────────────
-- La suppression d'un compte efface l'utilisateur de ces tables : sans index, elle les
-- parcourt en entier.
create index purchase_events_user_idx on public.purchase_events (user_id);
create index one_time_purchases_user_idx on public.one_time_purchases (user_id);

-- Lue par la fonction `exam` avec le rôle service, sans dépendre des droits automatiques.
grant select on table public.exams to service_role;

revoke execute on function
  public.failed_ai_calls(uuid, text),
  public.history_start_date(uuid)
from public, anon, authenticated;
