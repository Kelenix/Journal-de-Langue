-- Inc-2 : journal quotidien et correction de base (US-05 à US-07).
-- L'app lit ses journaux corrigés ; réservation, correction et quota passent par des
-- fonctions appelées par l'Edge Function `correct-entry` avec le rôle service.

create type public.error_category as enum (
  'spelling', 'grammar', 'conjugation', 'vocabulary', 'register', 'phrasing', 'punctuation'
);

create table public.journal_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  language public.language_code not null,
  -- Jour civil de l'utilisateur, fourni par l'appareil et contrôlé par reserve_correction.
  entry_date date not null,
  original_text text not null,
  corrected_text text,
  sentence_count smallint not null,
  idempotency_key uuid not null,
  created_at timestamptz not null default now(),
  -- Null tant que la correction est en cours.
  corrected_at timestamptz,
  unique (user_id, idempotency_key),
  constraint journal_entries_correction_complete
    check ((corrected_at is null) = (corrected_text is null))
);

create index journal_entries_user_date_idx
  on public.journal_entries (user_id, entry_date desc);

create table public.correction_items (
  entry_id uuid not null references public.journal_entries (id) on delete cascade,
  position smallint not null,
  original text not null,
  corrected text not null,
  category public.error_category not null,
  explanation text not null,
  primary key (entry_id, position)
);

-- Coût de l'IA par utilisateur (INTAKE §8.3). Conservé, anonymisé, après suppression du compte.
create table public.ai_usage (
  id bigint generated always as identity primary key,
  user_id uuid references public.profiles (id) on delete set null,
  feature text not null,
  model text not null,
  input_tokens integer not null check (input_tokens >= 0),
  output_tokens integer not null check (output_tokens >= 0),
  created_at timestamptz not null default now()
);

create index ai_usage_user_created_idx on public.ai_usage (user_id, created_at);

-- Accès
alter table public.journal_entries enable row level security;
alter table public.correction_items enable row level security;
alter table public.ai_usage enable row level security;

revoke all on table public.journal_entries, public.correction_items, public.ai_usage
  from anon, authenticated;
grant select on table public.journal_entries, public.correction_items to authenticated;
grant all on table public.journal_entries, public.correction_items, public.ai_usage
  to service_role;

create policy journal_entries_select_own_corrected on public.journal_entries
  for select to authenticated
  using ((select auth.uid()) = user_id and corrected_at is not null);

create policy correction_items_select_own on public.correction_items
  for select to authenticated
  using (
    exists (
      select 1
        from public.journal_entries as entry
       where entry.id = correction_items.entry_id
         and entry.user_id = (select auth.uid())
         and entry.corrected_at is not null
    )
  );

-- Une phrase se termine par . ! ? … ou un retour à la ligne.
-- Même règle que `countSentences` dans l'app (lib/features/journal/domain/sentences.dart).
create function public.count_sentences(p_text text)
returns integer
language sql
immutable
set search_path = ''
as $$
  select count(*)::integer
    from regexp_split_to_table(p_text, '[.!?…]+|[\n\r]+') as segment
   where segment ~ '\S';
$$;

-- Limites de l'offre gratuite (INTAKE §3.1). Les offres payantes étendront cette fonction.
create function public.plan_limits()
returns table (max_sentences integer, max_characters integer, daily_corrections integer)
language sql
immutable
set search_path = ''
as $$
  select 7, 1000, 1;
$$;

-- Réserve la correction du jour pour un texte, ou dit pourquoi elle est refusée.
-- Retour : {status: 'reserved' | 'corrected', entry_id} ou {status: 'denied', reason, ...}.
create function public.reserve_correction(
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

  select * into v_limits from public.plan_limits();
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

-- Enregistre la correction, ses points d'erreur et son coût, en une seule transaction.
create function public.complete_correction(
  p_entry_id uuid,
  p_corrected_text text,
  p_items jsonb,
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
  update public.journal_entries
     set corrected_text = p_corrected_text,
         corrected_at = now()
   where id = p_entry_id
     and corrected_at is null
  returning user_id into v_user_id;
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

  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
  values (v_user_id, 'correction_basic', p_model, p_input_tokens, p_output_tokens);
end;
$$;

-- Annule une réservation dont la correction a échoué : le quota du jour est rendu.
create function public.release_correction(p_entry_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.journal_entries
   where id = p_entry_id and corrected_at is null;
$$;

-- Ce que l'utilisateur connecté peut encore faire le jour donné.
create function public.get_entitlements(p_entry_date date)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
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
  from public.plan_limits() as limits;
$$;

revoke execute on function
  public.count_sentences(text),
  public.plan_limits(),
  public.reserve_correction(uuid, public.language_code, date, text, uuid),
  public.complete_correction(uuid, text, jsonb, text, integer, integer),
  public.release_correction(uuid),
  public.get_entitlements(date)
from public, anon, authenticated;

grant execute on function
  public.reserve_correction(uuid, public.language_code, date, text, uuid),
  public.complete_correction(uuid, text, jsonb, text, integer, integer),
  public.release_correction(uuid)
to service_role;

grant execute on function public.get_entitlements(date) to authenticated;
