-- Incrément 9 : coût de l'IA par utilisateur et rétention à 7 jours (US-24, ADR-006).
-- Lisibles seulement avec le rôle service : éditeur SQL du tableau de bord Supabase.

-- Prix publics des modèles, en dollars par million de tokens (ADR-032). À mettre à jour
-- quand un prix change ou qu'un nouveau modèle est utilisé : un appel à un modèle absent
-- de cette table est compté dans `unpriced_calls`, pas dans le coût.
create table public.ai_model_prices (
  model text primary key,
  input_usd_per_mtok numeric(10, 4) not null check (input_usd_per_mtok >= 0),
  output_usd_per_mtok numeric(10, 4) not null check (output_usd_per_mtok >= 0)
);

alter table public.ai_model_prices enable row level security;
revoke all on table public.ai_model_prices from anon, authenticated;

-- Claude Haiku 5.5 : tarif des requêtes de 100 000 tokens au plus, toujours le cas ici.
insert into public.ai_model_prices (model, input_usd_per_mtok, output_usd_per_mtok)
values
  ('claude-haiku-5-5', 0.10, 0.50),
  ('claude-sonnet-5-5', 2.00, 10.00);

-- Coût par utilisateur et par mois (UTC). Un compte supprimé garde ses lignes d'usage,
-- sans utilisateur : elles comptent dans le coût total.
create view public.v_ai_cost_per_user
with (security_invoker = true) as
select
  date_trunc('month', usage.created_at at time zone 'utc')::date as month,
  usage.user_id,
  count(*) as calls,
  sum(usage.input_tokens) as input_tokens,
  sum(usage.output_tokens) as output_tokens,
  round(
    coalesce(sum(usage.input_tokens * price.input_usd_per_mtok
                 + usage.output_tokens * price.output_usd_per_mtok), 0) / 1000000,
    4) as cost_usd,
  count(*) filter (where price.model is null) as unpriced_calls
from public.ai_usage as usage
left join public.ai_model_prices as price on price.model = usage.model
group by 1, 2;

-- Coût par utilisateur actif : un utilisateur est actif un mois s'il a fait au moins un
-- appel à l'IA (chaque correction en est un).
create view public.v_ai_cost_per_month
with (security_invoker = true) as
select
  month,
  count(user_id) as active_users,
  sum(cost_usd) as cost_usd,
  round(sum(cost_usd) / nullif(count(user_id), 0), 4) as cost_per_active_user_usd,
  sum(unpriced_calls) as unpriced_calls
from public.v_ai_cost_per_user
group by month;

-- Rétention à 7 jours par semaine d'inscription (UTC) : part des inscrits qui ont écrit
-- un journal ou fait un exercice le 7e jour après leur inscription. Seules les semaines
-- dont tous les 7e jours sont passés apparaissent.
create view public.v_retention_d7
with (security_invoker = true) as
with activity as (
  select entry.user_id, (entry.created_at at time zone 'utc')::date as day
    from public.journal_entries as entry
  union
  select attempt.user_id, (attempt.created_at at time zone 'utc')::date
    from public.exercise_attempts as attempt
),
cohort as (
  select
    date_trunc('week', profile.created_at at time zone 'utc')::date as cohort_week,
    exists (
      select 1 from activity
       where activity.user_id = profile.id
         and activity.day = (profile.created_at at time zone 'utc')::date + 7
    ) as is_retained
  from public.profiles as profile
)
select
  cohort_week,
  count(*) as signups,
  count(*) filter (where is_retained) as retained_d7,
  round(100.0 * count(*) filter (where is_retained) / count(*), 1) as retention_d7_pct
from cohort
where cohort_week + 13 < (now() at time zone 'utc')::date
group by cohort_week;

revoke all on public.v_ai_cost_per_user, public.v_ai_cost_per_month, public.v_retention_d7
  from anon, authenticated;
grant select on public.v_ai_cost_per_user, public.v_ai_cost_per_month, public.v_retention_d7,
  public.ai_model_prices
  to service_role;
