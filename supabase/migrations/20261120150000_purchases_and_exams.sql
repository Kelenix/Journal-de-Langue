-- Incrément 7 : achats ponctuels (US-18, 19, 21) et simulation d'examen (US-20).

-- ── Tables ──────────────────────────────────────────────────────────────────
-- Ce que l'utilisateur a acheté et pas encore utilisé. Les crédits de correction et
-- d'examen sont consommables ; « sans publicité » est un achat définitif (INTAKE §4, §5.3).
create table public.wallets (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  correction_credits integer not null default 0 check (correction_credits >= 0),
  exam_credits integer not null default 0 check (exam_credits >= 0),
  ads_removed boolean not null default false,
  updated_at timestamptz not null default now()
);

-- Accès à une langue pendant 30 jours (INTAKE §4.2). Un nouvel achat prolonge l'accès.
create table public.language_passes (
  user_id uuid not null references public.profiles (id) on delete cascade,
  language public.language_code not null,
  expires_at timestamptz not null,
  primary key (user_id, language)
);

-- Achats uniques reçus de RevenueCat, gardés pour pouvoir les reprendre s'ils sont remboursés.
create table public.one_time_purchases (
  transaction_id text primary key,
  user_id uuid references public.profiles (id) on delete set null,
  product_id text not null,
  quantity integer not null check (quantity > 0),
  purchased_at timestamptz not null,
  refunded_at timestamptz
);

-- Langue ouverte par un accès de 30 jours et jamais choisie par l'utilisateur : elle ne
-- compte pas dans la limite de l'offre et se verrouille à l'expiration de l'accès.
alter table public.user_languages
  add column activated_by_pass boolean not null default false;

-- Origine d'une correction : quota du jour de l'offre ou crédit acheté (hypothèse H6).
create type public.correction_source as enum ('plan', 'credit');
alter table public.journal_entries
  add column source public.correction_source not null default 'plan';

create type public.exam_level as enum ('A2', 'B1', 'B2', 'C1');
create type public.exam_status as enum ('preparing', 'in_progress', 'grading', 'graded');

-- Simulation d'examen : un sujet, une rédaction, une correction renforcée (ADR-028).
create table public.exams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  language public.language_code not null,
  level public.exam_level not null,
  ui_locale text not null check (ui_locale in ('fr', 'en')),
  status public.exam_status not null default 'preparing',
  -- Sujet : {title, task, min_words, max_words}.
  prompt jsonb,
  answer text check (char_length(answer) <= 6000),
  -- Correction : {score, level_estimate, summary, criteria, corrected_text, items,
  -- revision_plan}.
  result jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  graded_at timestamptz
);

-- Une seule simulation non terminée à la fois : elle reste disponible si elle est interrompue.
create unique index exams_one_open_idx on public.exams (user_id) where status <> 'graded';
create index exams_user_idx on public.exams (user_id, created_at desc);

alter table public.wallets enable row level security;
alter table public.language_passes enable row level security;
alter table public.one_time_purchases enable row level security;
alter table public.exams enable row level security;

revoke all on table public.wallets, public.language_passes, public.one_time_purchases,
  public.exams from anon, authenticated;
grant select on table public.wallets, public.language_passes, public.exams to authenticated;

create policy wallets_select_own on public.wallets
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy language_passes_select_own on public.language_passes
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy exams_select_own on public.exams
  for select to authenticated
  using ((select auth.uid()) = user_id);

-- ── Produits vendus à l'unité ───────────────────────────────────────────────
-- Identifiants à créer à l'identique dans les stores (docs/manual-tasks.md). Un accès
-- langue par langue : le store ne transmet rien d'autre que l'identifiant du produit.
create function public.one_time_product(p_product_id text)
returns table (kind text, amount integer, language public.language_code)
language sql
immutable
set search_path = ''
as $$
  select product.kind, product.amount, product.language
    from (values
      ('corrections_10', 'credits', 10, null::public.language_code),
      ('corrections_50', 'credits', 50, null),
      ('exam_pack', 'exam', 1, null),
      ('remove_ads', 'ads', 1, null),
      -- Montant : nombre de jours d'accès.
      ('language_pass_en', 'language_pass', 30, 'en'),
      ('language_pass_es', 'language_pass', 30, 'es'),
      ('language_pass_de', 'language_pass', 30, 'de'),
      ('language_pass_fr', 'language_pass', 30, 'fr')
    ) as product (id, kind, amount, language)
   where product.id = p_product_id;
$$;

-- Donne (p_sign = 1) ou reprend (p_sign = -1) ce qu'un achat apporte. Un crédit déjà
-- utilisé ne peut pas être repris : le solde ne descend pas sous zéro.
create function public.grant_one_time_product(
  p_user_id uuid,
  p_product_id text,
  p_quantity integer,
  p_sign integer
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_product record;
begin
  select * into v_product from public.one_time_product(p_product_id);

  insert into public.wallets (user_id) values (p_user_id) on conflict (user_id) do nothing;

  case v_product.kind
    when 'credits' then
      update public.wallets
         set correction_credits = greatest(
               0, correction_credits + p_sign * v_product.amount * p_quantity),
             updated_at = now()
       where user_id = p_user_id;
    when 'exam' then
      update public.wallets
         set exam_credits = greatest(0, exam_credits + p_sign * v_product.amount * p_quantity),
             updated_at = now()
       where user_id = p_user_id;
    when 'ads' then
      update public.wallets
         set ads_removed = p_sign > 0, updated_at = now()
       where user_id = p_user_id;
    when 'language_pass' then
      if p_sign > 0 then
        insert into public.language_passes (user_id, language, expires_at)
        values (
          p_user_id, v_product.language, now() + interval '1 day' * v_product.amount * p_quantity
        )
        on conflict (user_id, language) do update
          set expires_at = greatest(public.language_passes.expires_at, now())
                           + interval '1 day' * v_product.amount * p_quantity;
        -- La langue débloquée devient la langue du journal. Une langue déjà choisie par
        -- l'utilisateur le reste à l'expiration de l'accès.
        insert into public.user_languages
          (user_id, language, activated_at, activated_by_pass)
        values (p_user_id, v_product.language, clock_timestamp(), true)
        on conflict (user_id, language) do update
          set activated_by_pass = public.user_languages.activated_by_pass
                                  or not public.user_languages.is_active,
              is_active = true,
              activated_at = clock_timestamp();
      else
        update public.language_passes
           set expires_at = greatest(
                 now(), expires_at - interval '1 day' * v_product.amount * p_quantity)
         where user_id = p_user_id and language = v_product.language;
      end if;
  end case;
end;
$$;

-- Applique une notification d'achat unique (NON_RENEWING_PURCHASE) ou de son
-- remboursement (CANCELLATION pour CUSTOMER_SUPPORT, avec le même transaction_id).
-- Retour : 'applied', 'duplicate' ou 'ignored'.
create function public.apply_one_time_purchase(
  p_event_id text,
  p_user_id uuid,
  p_type text,
  p_product_id text,
  p_transaction_id text,
  p_quantity integer,
  p_cancel_reason text,
  p_event_at timestamptz
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_known_user boolean;
  v_purchase public.one_time_purchases;
begin
  select exists (select 1 from public.profiles where id = p_user_id) into v_known_user;

  insert into public.purchase_events (event_id, user_id, type, product_id, event_at)
  values (
    p_event_id, case when v_known_user then p_user_id end, p_type, p_product_id, p_event_at
  )
  on conflict (event_id) do nothing;
  if not found then
    return 'duplicate';
  end if;

  if not v_known_user or p_transaction_id is null then
    return 'ignored';
  end if;

  if p_type = 'NON_RENEWING_PURCHASE' then
    insert into public.one_time_purchases
      (transaction_id, user_id, product_id, quantity, purchased_at)
    values (p_transaction_id, p_user_id, p_product_id, greatest(coalesce(p_quantity, 1), 1),
            p_event_at)
    on conflict (transaction_id) do nothing
    returning * into v_purchase;
    -- Même achat déjà reçu sous un autre identifiant de notification.
    if not found then
      return 'duplicate';
    end if;
    perform public.grant_one_time_product(p_user_id, p_product_id, v_purchase.quantity, 1);
    return 'applied';
  end if;

  if p_type = 'CANCELLATION' and p_cancel_reason = 'CUSTOMER_SUPPORT' then
    update public.one_time_purchases
       set refunded_at = now()
     where transaction_id = p_transaction_id
       and refunded_at is null
       and user_id is not null
    returning * into v_purchase;
    if not found then
      return 'ignored';
    end if;
    perform public.grant_one_time_product(
      v_purchase.user_id, v_purchase.product_id, v_purchase.quantity, -1);
    return 'applied';
  end if;

  return 'ignored';
end;
$$;

-- Point d'entrée de la fonction revenuecat-webhook : aiguille vers les abonnements ou les
-- achats uniques selon le produit.
create function public.apply_store_event(
  p_event_id text,
  p_user_id uuid,
  p_type text,
  p_product_id text,
  p_expires_at timestamptz,
  p_in_trial boolean,
  p_event_at timestamptz,
  p_transaction_id text,
  p_quantity integer,
  p_cancel_reason text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
begin
  if exists (select 1 from public.one_time_product(p_product_id)) then
    return public.apply_one_time_purchase(
      p_event_id, p_user_id, p_type, p_product_id, p_transaction_id, p_quantity,
      p_cancel_reason, p_event_at);
  end if;
  return public.apply_subscription_event(
    p_event_id, p_user_id, p_type, p_product_id, p_expires_at, p_in_trial, p_event_at);
end;
$$;

-- Achats de l'utilisateur connecté.
create function public.get_wallet()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'correction_credits', coalesce(wallet.correction_credits, 0),
    'exam_credits', coalesce(wallet.exam_credits, 0),
    'ads_removed', coalesce(wallet.ads_removed, false),
    'language_passes', coalesce((
      select jsonb_agg(
               jsonb_build_object('language', pass.language, 'expires_at', pass.expires_at)
               order by pass.expires_at)
        from public.language_passes as pass
       where pass.user_id = me.id and pass.expires_at > now()
    ), '[]'::jsonb)
  )
  from (select (select auth.uid()) as id) as me
  left join public.wallets as wallet on wallet.user_id = me.id;
$$;

-- ── Langues : un accès de 30 jours s'ajoute à la limite de l'offre ──────────
create or replace function public.usable_languages(p_user_id uuid)
returns table (language public.language_code)
language sql
stable
set search_path = ''
as $$
  with passes as (
    select pass.language
      from public.language_passes as pass
     where pass.user_id = p_user_id and pass.expires_at > now()
  ), plan_languages as (
    select user_language.language
      from public.user_languages as user_language
     where user_language.user_id = p_user_id
       and user_language.is_active
       and not user_language.activated_by_pass
     order by user_language.activated_at desc, user_language.language
     limit (select limits.max_languages from public.plan_limits(p_user_id) as limits)
  )
  select user_language.language
    from public.user_languages as user_language
   where user_language.user_id = p_user_id
     and user_language.is_active
     and (user_language.language in (select passes.language from passes)
          or user_language.language in (select plan_languages.language from plan_languages))
   order by user_language.activated_at desc, user_language.language;
$$;

create or replace function public.activate_language(p_language public.language_code)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_max_languages integer;
  v_has_pass boolean;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '28000';
  end if;

  -- Un appel à la fois par utilisateur : la limite ne peut pas être dépassée en parallèle.
  perform 1 from public.profiles where id = v_user_id for update;

  select limits.max_languages into v_max_languages from public.plan_limits(v_user_id) as limits;
  select exists (
    select 1 from public.language_passes
     where user_id = v_user_id and language = p_language and expires_at > now()
  ) into v_has_pass;

  if v_has_pass then
    -- Langue débloquée pour 30 jours : elle devient la langue du journal sans rien retirer.
    null;
  elsif v_max_languages = 1 then
    -- Gratuit : la nouvelle langue remplace la précédente, mais pas une langue débloquée.
    update public.user_languages as user_language
       set is_active = false
     where user_language.user_id = v_user_id
       and user_language.language <> p_language
       and user_language.is_active
       and not exists (
         select 1 from public.language_passes as pass
          where pass.user_id = v_user_id
            and pass.language = user_language.language
            and pass.expires_at > now()
       );
  elsif not exists (
    select 1 from public.user_languages
     where user_id = v_user_id and language = p_language and is_active
  ) and (
    select count(*)
      from public.user_languages as user_language
     where user_language.user_id = v_user_id
       and user_language.is_active
       and not user_language.activated_by_pass
  ) >= v_max_languages then
    raise exception 'language_limit' using errcode = 'P0001';
  end if;

  -- clock_timestamp et non now() : deux choix dans une même transaction restent ordonnés.
  -- Choisir une langue sans accès en cours en fait une langue de l'utilisateur.
  insert into public.user_languages (user_id, language, activated_at, activated_by_pass)
  values (v_user_id, p_language, clock_timestamp(), v_has_pass)
  on conflict (user_id, language)
  do update set is_active = true,
                activated_at = clock_timestamp(),
                activated_by_pass = v_has_pass and public.user_languages.activated_by_pass;
end;
$$;

-- ── Corrections : un crédit acheté prend le relais du quota du jour ────────
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
    if v_credits_left <= 0 then
      return jsonb_build_object('status', 'denied', 'reason', 'daily_limit');
    end if;
    v_source := 'credit';
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

-- Droits du jour : le quota de l'offre ne compte que les corrections qu'il a payées ;
-- les crédits restants sont donnés à part.
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
    ), 0)
  )
  from public.plan_limits((select auth.uid())) as limits;
$$;

-- ── Simulation d'examen (US-20) ─────────────────────────────────────────────
-- Retour : {status: 'preparing', exam_id} (crédit débité, sujet à créer),
-- {status: 'open', exam_id} (simulation déjà en cours, rendue sans nouveau débit),
-- {status: 'busy'} ou {status: 'denied', reason}.
create function public.reserve_exam(
  p_user_id uuid,
  p_language public.language_code,
  p_level public.exam_level,
  p_ui_locale text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_exam public.exams;
  v_abandoned integer;
begin
  perform 1 from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'unknown_user' using errcode = 'P0002';
  end if;

  -- Une préparation interrompue (fonction arrêtée en route) rend son crédit.
  delete from public.exams
   where user_id = p_user_id
     and status = 'preparing'
     and updated_at < now() - interval '2 minutes';
  get diagnostics v_abandoned = row_count;
  if v_abandoned > 0 then
    update public.wallets
       set exam_credits = exam_credits + v_abandoned, updated_at = now()
     where user_id = p_user_id;
  end if;

  select * into v_exam from public.exams where user_id = p_user_id and status <> 'graded';
  if found then
    if v_exam.status = 'preparing' then
      return jsonb_build_object('status', 'busy');
    end if;
    return jsonb_build_object('status', 'open', 'exam_id', v_exam.id);
  end if;

  if not public.is_usable_language(p_user_id, p_language) then
    return jsonb_build_object('status', 'denied', 'reason', 'language_not_active');
  end if;

  update public.wallets
     set exam_credits = exam_credits - 1, updated_at = now()
   where user_id = p_user_id and exam_credits > 0;
  if not found then
    return jsonb_build_object('status', 'denied', 'reason', 'no_exam_credit');
  end if;

  insert into public.exams (user_id, language, level, ui_locale)
  values (p_user_id, p_language, p_level, p_ui_locale)
  returning * into v_exam;

  return jsonb_build_object('status', 'preparing', 'exam_id', v_exam.id);
end;
$$;

-- Sujet créé : la simulation commence.
create function public.start_exam(
  p_exam_id uuid,
  p_prompt jsonb,
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
  v_user_id uuid;
begin
  update public.exams
     set status = 'in_progress', prompt = p_prompt, updated_at = now()
   where id = p_exam_id and status = 'preparing'
  returning user_id into v_user_id;
  if not found then
    raise exception 'exam_not_found' using errcode = 'P0002';
  end if;

  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
  values (v_user_id, 'exam_topic', p_model, p_input_tokens, p_output_tokens);
end;
$$;

-- Sujet impossible à créer : la simulation est annulée et le crédit rendu.
create function public.release_exam(p_exam_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid;
begin
  delete from public.exams
   where id = p_exam_id and status = 'preparing'
  returning user_id into v_user_id;
  if found then
    update public.wallets
       set exam_credits = exam_credits + 1, updated_at = now()
     where user_id = v_user_id;
  end if;
end;
$$;

-- Prend la rédaction à corriger. Retour : {status: 'claimed', ...} avec ce qu'il faut pour
-- la correction, {status: 'graded'}, {status: 'busy'} ou {status: 'denied', reason}.
create function public.claim_exam_grading(p_user_id uuid, p_exam_id uuid, p_answer text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
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
  -- Une correction jamais terminée (fonction arrêtée en route) peut être relancée.
  if v_exam.status = 'grading' and v_exam.updated_at > now() - interval '2 minutes' then
    return jsonb_build_object('status', 'busy');
  end if;
  if btrim(coalesce(p_answer, '')) = '' or char_length(p_answer) > 6000 then
    return jsonb_build_object('status', 'denied', 'reason', 'invalid_text');
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

create function public.complete_exam(
  p_exam_id uuid,
  p_result jsonb,
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
  v_user_id uuid;
begin
  update public.exams
     set status = 'graded', result = p_result, graded_at = now(), updated_at = now()
   where id = p_exam_id and status = 'grading'
  returning user_id into v_user_id;
  if not found then
    raise exception 'exam_not_found' using errcode = 'P0002';
  end if;

  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
  values (v_user_id, 'exam_grading', p_model, p_input_tokens, p_output_tokens);
end;
$$;

-- Correction impossible : la rédaction est gardée et peut être renvoyée.
create function public.release_exam_grading(p_exam_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.exams
     set status = 'in_progress', updated_at = now()
   where id = p_exam_id and status = 'grading';
$$;

-- Brouillon de la rédaction, enregistré pendant la saisie : une simulation interrompue
-- garde le texte déjà écrit, sur tous les appareils.
create function public.save_exam_draft(p_exam_id uuid, p_answer text)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.exams
     set answer = left(p_answer, 6000)
   where id = p_exam_id
     and user_id = (select auth.uid())
     and status = 'in_progress';
$$;

-- ── Droits d'exécution ──────────────────────────────────────────────────────
revoke execute on function
  public.one_time_product(text),
  public.grant_one_time_product(uuid, text, integer, integer),
  public.apply_one_time_purchase(text, uuid, text, text, text, integer, text, timestamptz),
  public.apply_store_event(
    text, uuid, text, text, timestamptz, boolean, timestamptz, text, integer, text),
  public.get_wallet(),
  public.reserve_exam(uuid, public.language_code, public.exam_level, text),
  public.start_exam(uuid, jsonb, text, integer, integer),
  public.release_exam(uuid),
  public.claim_exam_grading(uuid, uuid, text),
  public.complete_exam(uuid, jsonb, text, integer, integer),
  public.release_exam_grading(uuid),
  public.save_exam_draft(uuid, text)
from public, anon, authenticated;

grant execute on function
  public.apply_store_event(
    text, uuid, text, text, timestamptz, boolean, timestamptz, text, integer, text),
  public.reserve_exam(uuid, public.language_code, public.exam_level, text),
  public.start_exam(uuid, jsonb, text, integer, integer),
  public.release_exam(uuid),
  public.claim_exam_grading(uuid, uuid, text),
  public.complete_exam(uuid, jsonb, text, integer, integer),
  public.release_exam_grading(uuid)
to service_role;

grant execute on function public.get_wallet(), public.save_exam_draft(uuid, text)
  to authenticated;
