-- Incrément 9 : l'historique est lu par pages. L'app apprend ici, sans le charger, si
-- l'utilisateur a déjà un journal corrigé (les offres payantes ne sont proposées qu'après).
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
           (count(*) filter (where entry.entry_date < public.history_start_date()))::integer
             as locked,
           count(*)::integer as corrected
           from public.journal_entries as entry
          where entry.user_id = (select auth.uid())
            and entry.corrected_at is not null
       ) as counts;
$$;
