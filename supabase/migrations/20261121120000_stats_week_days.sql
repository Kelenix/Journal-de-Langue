-- Refonte de l'interface : l'écran Journal montre la semaine en cours, jour par jour.
-- get_stats ajoute, pour toutes les offres, les jours de cette semaine (du lundi à
-- aujourd'hui) qui ont un journal corrigé, toutes langues confondues comme la série.
create or replace function public.get_stats(p_language public.language_code, p_today date)
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
    'journals', v_journals,
    'week_days', coalesce((
      select jsonb_agg(distinct entry.entry_date order by entry.entry_date)
        from public.journal_entries as entry
       where entry.user_id = v_user_id
         and entry.corrected_at is not null
         and entry.entry_date >= date_trunc('week', v_today)::date
         and entry.entry_date <= v_today
    ), '[]'::jsonb)
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
