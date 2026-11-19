-- Inc-4 : abonnements Premium (US-10, US-11).
-- Les droits viennent des notifications du prestataire d'achats (RevenueCat), reçues par
-- l'Edge Function `revenuecat-webhook`. L'app ne peut que lire son abonnement.

create type public.plan as enum ('weekly', 'monthly', 'annual');

create table public.subscriptions (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  plan public.plan not null,
  -- L'abonnement donne ses droits tant que cette date n'est pas passée.
  expires_at timestamptz not null,
  in_trial boolean not null default false,
  -- Date de la notification la plus récente appliquée : une notification plus ancienne
  -- arrivée en retard ne l'écrase pas.
  last_event_at timestamptz not null,
  updated_at timestamptz not null default now()
);

-- Notifications déjà reçues : une notification rejouée n'est appliquée qu'une fois.
create table public.purchase_events (
  event_id text primary key,
  user_id uuid references public.profiles (id) on delete set null,
  type text not null,
  product_id text,
  event_at timestamptz not null,
  received_at timestamptz not null default now()
);

alter table public.subscriptions enable row level security;
alter table public.purchase_events enable row level security;

revoke all on table public.subscriptions, public.purchase_events from anon, authenticated;
grant select on table public.subscriptions to authenticated;
grant all on table public.subscriptions, public.purchase_events to service_role;

create policy subscriptions_select_own on public.subscriptions
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- Offre correspondant à un identifiant de produit des stores. Sur Google Play, RevenueCat
-- envoie « <abonnement>:<offre de base> » : seul l'identifiant de l'abonnement compte.
-- Les produits doivent être créés avec ces identifiants (docs/manual-tasks.md).
create function public.plan_of_product(p_product_id text)
returns public.plan
language sql
immutable
set search_path = ''
as $$
  select case split_part(p_product_id, ':', 1)
    when 'premium_weekly' then 'weekly'::public.plan
    when 'premium_monthly' then 'monthly'::public.plan
    when 'premium_annual' then 'annual'::public.plan
  end;
$$;

-- Applique une notification d'abonnement.
-- Retour : 'applied', 'duplicate' (déjà reçue), 'stale' (plus ancienne que l'état connu) ou
-- 'ignored' (utilisateur ou produit inconnu, ou notification sans date d'expiration).
create function public.apply_subscription_event(
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

  insert into public.subscriptions (user_id, plan, expires_at, in_trial, last_event_at)
  values (p_user_id, v_plan, p_expires_at, p_in_trial, p_event_at)
  on conflict (user_id) do update
    set plan = excluded.plan,
        expires_at = excluded.expires_at,
        in_trial = excluded.in_trial,
        last_event_at = excluded.last_event_at,
        updated_at = now()
    where public.subscriptions.last_event_at <= excluded.last_event_at;
  if not found then
    return 'stale';
  end if;

  return 'applied';
end;
$$;

-- ── Limites selon l'offre ───────────────────────────────────────────────────
-- Gratuit (INTAKE §3.1) : 7 phrases, 1 correction et 5 mots par jour, 4 jours d'historique.
-- Premium (INTAKE §3.3, plafonds « équitables » de l'hypothèse H4) : 40 phrases,
-- 30 corrections par jour, vocabulaire et historique sans limite (valeur nulle).
drop function public.plan_limits();

create function public.plan_limits(p_user_id uuid)
returns table (
  plan public.plan,
  max_sentences integer,
  max_characters integer,
  daily_corrections integer,
  daily_vocabulary integer,
  history_days integer
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
         case when active.plan is null then 4 end
    from (
      select (
        select subscription.plan
          from public.subscriptions as subscription
         where subscription.user_id = p_user_id
           and subscription.expires_at > now()
      ) as plan
    ) as active;
$$;

create or replace function public.history_start_date()
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select case
           when limits.history_days is null then '-infinity'::date
           else (now() at time zone 'Etc/GMT+12')::date - (limits.history_days - 1)
         end
    from public.plan_limits((select auth.uid())) as limits;
$$;

create or replace function public.get_history_overview()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'history_days', limits.history_days,
    'locked_entries', (
      select count(*)::integer
        from public.journal_entries
       where user_id = (select auth.uid())
         and corrected_at is not null
         and entry_date < public.history_start_date()
    )
  )
  from public.plan_limits((select auth.uid())) as limits;
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
      )
    )
  )
  from public.plan_limits((select auth.uid())) as limits;
$$;

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

  -- La date vient de l'appareil : elle doit être « aujourd'hui » dans au moins un fuseau
  -- horaire (UTC-12 à UTC+14) et ne peut pas reculer par rapport au dernier journal.
  if p_entry_date not between (now() at time zone 'Etc/GMT+12')::date
                          and (now() at time zone 'Etc/GMT-14')::date
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

  insert into public.journal_entries
    (user_id, language, entry_date, original_text, sentence_count, idempotency_key)
  values
    (p_user_id, p_language, p_entry_date, p_text, v_sentence_count, p_idempotency_key)
  returning id into v_entry_id;

  return jsonb_build_object('status', 'reserved', 'entry_id', v_entry_id);
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
  values (v_entry.user_id, 'correction_basic', p_model, p_input_tokens, p_output_tokens);
end;
$$;

revoke execute on function
  public.plan_of_product(text),
  public.plan_limits(uuid),
  public.apply_subscription_event(text, uuid, text, text, timestamptz, boolean, timestamptz)
from public, anon, authenticated;

grant execute on function
  public.apply_subscription_event(text, uuid, text, text, timestamptz, boolean, timestamptz)
to service_role;
