-- Inc-3 : vocabulaire à réviser et historique (US-08, US-09).

-- ── Vocabulaire ─────────────────────────────────────────────────────────────
create table public.vocabulary_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  entry_id uuid not null references public.journal_entries (id) on delete cascade,
  language public.language_code not null,
  term text not null,
  translation text not null,
  example text not null,
  -- Null tant que l'utilisateur n'a pas marqué le mot comme appris.
  learned_at timestamptz,
  created_at timestamptz not null default now()
);

-- Un mot n'est proposé qu'une fois par utilisateur et par langue.
create unique index vocabulary_items_user_term_idx
  on public.vocabulary_items (user_id, language, lower(term));
create index vocabulary_items_entry_idx on public.vocabulary_items (entry_id);

alter table public.vocabulary_items enable row level security;

revoke all on table public.vocabulary_items from anon, authenticated;
-- L'app lit ses mots et ne peut modifier que leur état « appris ».
grant select, update (learned_at) on table public.vocabulary_items to authenticated;
grant all on table public.vocabulary_items to service_role;

create policy vocabulary_items_select_own on public.vocabulary_items
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy vocabulary_items_update_own on public.vocabulary_items
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- ── Limites de l'offre gratuite, complétées (INTAKE §3.1) ───────────────────
drop function public.plan_limits();

create function public.plan_limits()
returns table (
  max_sentences integer,
  max_characters integer,
  daily_corrections integer,
  daily_vocabulary integer,
  history_days integer
)
language sql
immutable
set search_path = ''
as $$
  select 7, 1000, 1, 5, 4;
$$;

revoke execute on function public.plan_limits() from public, anon, authenticated;

-- ── Historique limité aux derniers jours ────────────────────────────────────
-- Premier jour visible dans l'historique. Calculé sur le fuseau le plus en retard
-- (UTC-12) : aucun utilisateur ne voit moins de `history_days` jours.
create function public.history_start_date()
returns date
language sql
stable
security definer
set search_path = ''
as $$
  select (now() at time zone 'Etc/GMT+12')::date - (limits.history_days - 1)
    from public.plan_limits() as limits;
$$;

revoke execute on function public.history_start_date() from public, anon;
grant execute on function public.history_start_date() to authenticated;

-- Les journaux plus anciens restent en base mais ne sont plus lisibles par l'app
-- (leurs points d'erreur suivent, par la policy de correction_items).
drop policy journal_entries_select_own_corrected on public.journal_entries;

create policy journal_entries_select_own_recent on public.journal_entries
  for select to authenticated
  using (
    (select auth.uid()) = user_id
    and corrected_at is not null
    and entry_date >= (select public.history_start_date())
  );

-- Ce que l'historique de l'utilisateur connecté contient au-delà de ce qu'il peut lire.
create function public.get_history_overview()
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
  from public.plan_limits() as limits;
$$;

revoke execute on function public.get_history_overview() from public, anon;
grant execute on function public.get_history_overview() to authenticated;

-- ── La correction enregistre aussi le vocabulaire ───────────────────────────
drop function public.complete_correction(uuid, text, jsonb, text, integer, integer);

create function public.complete_correction(
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
  v_vocabulary_left integer;
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

  -- Vocabulaire : dans la limite quotidienne de l'offre, sans doublon.
  select (select daily_vocabulary from public.plan_limits()) - count(*)
    into v_vocabulary_left
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
   limit greatest(v_vocabulary_left, 0)
  on conflict (user_id, language, lower(term)) do nothing;

  insert into public.ai_usage (user_id, feature, model, input_tokens, output_tokens)
  values (v_entry.user_id, 'correction_basic', p_model, p_input_tokens, p_output_tokens);
end;
$$;

revoke execute on function
  public.complete_correction(uuid, text, jsonb, jsonb, text, integer, integer)
from public, anon, authenticated;

grant execute on function
  public.complete_correction(uuid, text, jsonb, jsonb, text, integer, integer)
to service_role;
