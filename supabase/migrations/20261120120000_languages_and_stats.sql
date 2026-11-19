-- Incrément 6 : plusieurs langues selon l'offre (US-04) et statistiques (US-16).

-- ── Limites de l'offre : nombre de langues ───────────────────────────────────
-- Gratuit : 1 langue ; Premium hebdomadaire ou mensuel : 3 ; annuel : les 4 (INTAKE §11).
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
  daily_rewrites integer,
  max_languages integer
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
         case when active.plan is null then 0 else 30 end,
         case active.plan when 'annual' then 4 when 'monthly' then 3 when 'weekly' then 3 else 1 end
    from (
      select (
        select subscription.plan
          from public.subscriptions as subscription
         where subscription.user_id = p_user_id
           and subscription.expires_at > now()
      ) as plan
    ) as active;
$$;

-- ── Langues utilisables ─────────────────────────────────────────────────────
-- Les langues actives les plus récemment choisies, dans la limite de l'offre. La première
-- est la langue en cours. Après la fin d'un abonnement, les autres restent actives (rien
-- n'est effacé) mais ne sont plus utilisables tant que l'offre ne le permet pas (ADR-025).
create function public.usable_languages(p_user_id uuid)
returns table (language public.language_code)
language sql
stable
set search_path = ''
as $$
  select user_language.language
    from public.user_languages as user_language
   where user_language.user_id = p_user_id
     and user_language.is_active
   order by user_language.activated_at desc, user_language.language
   limit (select limits.max_languages from public.plan_limits(p_user_id) as limits);
$$;

create function public.is_usable_language(p_user_id uuid, p_language public.language_code)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.usable_languages(p_user_id) as usable
     where usable.language = p_language
  );
$$;

-- Langues de l'utilisateur connecté, la langue en cours d'abord.
create function public.get_languages()
returns public.language_code[]
language sql
stable
security definer
set search_path = ''
as $$
  select array(
    select usable.language
      from public.usable_languages(auth.uid()) with ordinality as usable (language, position)
     order by usable.position
  );
$$;

-- Choisit la langue en cours. Gratuit : elle remplace la langue active. Premium : elle
-- s'ajoute aux langues actives, dans la limite de l'offre ; une langue déjà active
-- devient simplement la langue en cours.
create or replace function public.activate_language(p_language public.language_code)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_max_languages integer;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  -- Un appel à la fois par utilisateur : la limite ne peut pas être dépassée en parallèle.
  perform 1 from public.profiles where id = v_user_id for update;

  select limits.max_languages into v_max_languages from public.plan_limits(v_user_id) as limits;

  if v_max_languages = 1 then
    update public.user_languages
       set is_active = false
     where user_id = v_user_id
       and language <> p_language
       and is_active;
  elsif not exists (
    select 1 from public.user_languages
     where user_id = v_user_id and language = p_language and is_active
  ) and (
    select count(*) from public.user_languages where user_id = v_user_id and is_active
  ) >= v_max_languages then
    raise exception 'language_limit' using errcode = 'P0001';
  end if;

  -- clock_timestamp et non now() : deux choix dans une même transaction restent ordonnés.
  insert into public.user_languages (user_id, language, activated_at)
  values (v_user_id, p_language, clock_timestamp())
  on conflict (user_id, language)
  do update set is_active = true, activated_at = clock_timestamp();
end;
$$;

-- Retire une langue (Premium). Ses journaux et son vocabulaire sont conservés ; il reste
-- toujours au moins une langue active.
create function public.deactivate_language(p_language public.language_code)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  perform 1 from public.profiles where id = v_user_id for update;

  if not exists (
    select 1 from public.user_languages
     where user_id = v_user_id and is_active and language <> p_language
  ) then
    raise exception 'last_language' using errcode = 'P0001';
  end if;

  update public.user_languages
     set is_active = false
   where user_id = v_user_id and language = p_language;
end;
$$;

-- ── Fonctions reprises : la langue doit être utilisable, pas seulement active ────

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

-- ── Statistiques (US-16) ────────────────────────────────────────────────────
-- Série : jours consécutifs avec un journal corrigé, toutes langues confondues, jusqu'à
-- aujourd'hui ou hier (la série n'est pas perdue avant la fin de la journée). Visible en
-- gratuit. Le reste, pour la langue demandée, est réservé à Premium.
create function public.get_stats(p_language public.language_code, p_today date)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  -- Une date d'appareil invraisemblable est remplacée par la date du serveur.
  v_today date := case when public.is_plausible_local_date(p_today) then p_today else current_date end;
  v_is_premium boolean;
  v_streak integer;
  v_journals integer;
  v_stats jsonb;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  select limits.plan is not null into v_is_premium from public.plan_limits(v_user_id) as limits;

  -- Dans une suite de jours consécutifs, jour + rang (du plus récent au plus ancien) est
  -- constant : la série est la première de ces suites, si elle touche aujourd'hui ou hier.
  with days as (
    select distinct entry.entry_date as day
      from public.journal_entries as entry
     where entry.user_id = v_user_id
       and entry.corrected_at is not null
       and entry.entry_date <= v_today
  ), runs as (
    select day + (row_number() over (order by day desc))::integer as run_key from days
  )
  select count(*) into v_streak
    from runs
   where run_key = (select max(day) + 1 from days)
     and (select max(day) from days) >= v_today - 1;

  select count(*) into v_journals
    from public.journal_entries as entry
   where entry.user_id = v_user_id
     and entry.language = p_language
     and entry.corrected_at is not null;

  v_stats := jsonb_build_object(
    'is_premium', v_is_premium,
    'streak_days', v_streak,
    'journals', v_journals
  );
  if not v_is_premium then
    return v_stats;
  end if;

  return v_stats || jsonb_build_object(
    'words_learned', (
      select count(*) from public.vocabulary_items as word
       where word.user_id = v_user_id and word.language = p_language and word.learned_at is not null
    ),
    'words_total', (
      select count(*) from public.vocabulary_items as word
       where word.user_id = v_user_id and word.language = p_language
    ),
    'mistakes_by_category', coalesce((
      select jsonb_agg(jsonb_build_object('category', category, 'count', mistakes)
                       order by mistakes desc, category)
        from (
          select item.category, count(*) as mistakes
            from public.correction_items as item
            join public.journal_entries as entry on entry.id = item.entry_id
           where entry.user_id = v_user_id and entry.language = p_language
           group by item.category
        ) as by_category
    ), '[]'::jsonb),
    -- Fautes par phrase, semaine par semaine, sur les 8 dernières semaines.
    'weekly_mistake_rate', coalesce((
      select jsonb_agg(jsonb_build_object(
               'week_start', week_start,
               'mistakes_per_sentence', round(mistakes::numeric / sentences, 2))
             order by week_start)
        from (
          select date_trunc('week', entry.entry_date)::date as week_start,
                 sum((select count(*) from public.correction_items as item
                       where item.entry_id = entry.id)) as mistakes,
                 sum(entry.sentence_count) as sentences
            from public.journal_entries as entry
           where entry.user_id = v_user_id
             and entry.language = p_language
             and entry.corrected_at is not null
             and entry.entry_date > date_trunc('week', v_today)::date - 49
             and entry.entry_date <= v_today
           group by 1
        ) as weeks
       where sentences > 0
    ), '[]'::jsonb)
  );
end;
$$;

-- ── Droits d'exécution ──────────────────────────────────────────────────────
revoke execute on function
  public.plan_limits(uuid),
  public.usable_languages(uuid),
  public.is_usable_language(uuid, public.language_code),
  public.get_languages(),
  public.deactivate_language(public.language_code),
  public.get_stats(public.language_code, date)
from public, anon, authenticated;

grant execute on function
  public.get_languages(),
  public.deactivate_language(public.language_code),
  public.get_stats(public.language_code, date)
to authenticated;
