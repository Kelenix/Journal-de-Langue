-- Incrément 8 : publicités discrètes (US-22) et vidéos récompensées (US-23).

-- ── Récompenses des vidéos ──────────────────────────────────────────────────
-- Une vidéo vue en entier rapporte 1 correction ou 3 exercices. AdMob en informe le serveur
-- par un rappel signé (fonction admob-reward) : l'app ne peut pas s'attribuer une récompense.
-- Au plus une récompense de chaque sorte par jour (US-23).
create type public.ad_reward_kind as enum ('correction', 'exercises');

create table public.ad_rewards (
  -- Identifiant de la récompense chez AdMob : un même rappel ne compte qu'une fois.
  transaction_id text primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  kind public.ad_reward_kind not null,
  units integer not null check (units > 0),
  remaining integer not null check (remaining >= 0),
  -- Jour UTC de la récompense, pour le plafond quotidien.
  granted_on date not null default (now() at time zone 'utc')::date,
  created_at timestamptz not null default now()
);

create unique index ad_rewards_daily_cap_idx on public.ad_rewards (user_id, kind, granted_on);

alter table public.ad_rewards enable row level security;
revoke all on table public.ad_rewards from anon, authenticated;

alter type public.correction_source add value 'reward';

-- Publicités montrées à l'utilisateur : offre gratuite, sans l'achat « sans publicité », et
-- pas pendant les 14 jours qui suivent l'inscription (hypothèse H7).
create function public.ads_enabled(p_user_id uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select (select limits.plan from public.plan_limits(p_user_id) as limits) is null
     and not coalesce(
       (select wallet.ads_removed from public.wallets as wallet where wallet.user_id = p_user_id),
       false)
     and exists (
       select 1 from public.profiles as profile
        where profile.id = p_user_id and profile.created_at <= now() - interval '14 days'
     );
$$;

-- Unités offertes par des vidéos et pas encore utilisées.
create function public.ad_reward_left(p_user_id uuid, p_kind public.ad_reward_kind)
returns integer
language sql
stable
set search_path = ''
as $$
  select coalesce(sum(reward.remaining), 0)::integer
    from public.ad_rewards as reward
   where reward.user_id = p_user_id and reward.kind = p_kind;
$$;

-- Utilise une unité offerte, la plus ancienne d'abord. Retourne false s'il n'y en a plus.
create function public.use_ad_reward(p_user_id uuid, p_kind public.ad_reward_kind)
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
   );
  return found;
end;
$$;

-- Rappel AdMob vérifié. Retour : 'applied', 'duplicate' (déjà reçu), 'capped' (récompense
-- de cette sorte déjà obtenue aujourd'hui) ou 'ignored' (utilisateur inconnu ou sans
-- publicité).
create function public.grant_ad_reward(
  p_transaction_id text,
  p_user_id uuid,
  p_kind public.ad_reward_kind
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_units integer := case p_kind when 'correction' then 1 else 3 end;
begin
  if not exists (select 1 from public.profiles where id = p_user_id)
     or not public.ads_enabled(p_user_id) then
    return 'ignored';
  end if;

  insert into public.ad_rewards (transaction_id, user_id, kind, units, remaining)
  values (p_transaction_id, p_user_id, p_kind, v_units, v_units)
  on conflict (transaction_id) do nothing;
  if not found then
    return 'duplicate';
  end if;
  return 'applied';
exception
  when unique_violation then
    return 'capped';
end;
$$;

-- Ce que l'app doit savoir pour les publicités de l'utilisateur connecté.
create function public.get_ad_status()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'ads_enabled', public.ads_enabled(me.id),
    'correction_reward_available', not exists (
      select 1 from public.ad_rewards as reward
       where reward.user_id = me.id and reward.kind = 'correction'
         and reward.granted_on = (now() at time zone 'utc')::date),
    'exercises_reward_available', not exists (
      select 1 from public.ad_rewards as reward
       where reward.user_id = me.id and reward.kind = 'exercises'
         and reward.granted_on = (now() at time zone 'utc')::date),
    'reward_corrections', public.ad_reward_left(me.id, 'correction'),
    'reward_exercises', public.ad_reward_left(me.id, 'exercises')
  )
  from (select (select auth.uid()) as id) as me;
$$;

-- ── Fonctions reprises : les récompenses comptent avec le quota et les crédits ──

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

  -- Exactement un crédit par correction réussie (US-18).
  if v_entry.source = 'credit' then
    update public.wallets
       set correction_credits = correction_credits - 1, updated_at = now()
     where user_id = v_entry.user_id and correction_credits > 0;
  elsif v_entry.source = 'reward' then
    perform public.use_ad_reward(v_entry.user_id, 'correction');
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

create or replace function public.get_entitlements(p_entry_date date)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'plan', limits.plan,
    'max_sentences', limits.max_sentences,
    'max_characters', limits.max_characters,
    'corrections_left', greatest(
      0,
      limits.daily_corrections - (
        select count(*)::integer
          from public.journal_entries
         where user_id = (select auth.uid())
           and entry_date = p_entry_date
           and corrected_at is not null
           and source = 'plan'
      )
    ),
    'credits', coalesce((
      select wallet.correction_credits
        from public.wallets as wallet
       where wallet.user_id = (select auth.uid())
    ), 0),
    'reward_corrections', public.ad_reward_left((select auth.uid()), 'correction')
  )
  from public.plan_limits((select auth.uid())) as limits;
$$;

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
  -- Les exercices offerts par une vidéo s'ajoutent à la limite du jour (US-23).
  select v_limits.daily_exercises - count(*) + public.ad_reward_left(p_user_id, 'exercises')
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

-- ── Droits d'exécution ──────────────────────────────────────────────────────
revoke execute on function
  public.ads_enabled(uuid),
  public.ad_reward_left(uuid, public.ad_reward_kind),
  public.use_ad_reward(uuid, public.ad_reward_kind),
  public.grant_ad_reward(text, uuid, public.ad_reward_kind),
  public.get_ad_status()
from public, anon, authenticated;

grant execute on function public.grant_ad_reward(text, uuid, public.ad_reward_kind)
  to service_role;
grant execute on function public.get_ad_status() to authenticated;
