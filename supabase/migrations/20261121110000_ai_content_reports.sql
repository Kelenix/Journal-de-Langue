-- Incrément 9 : signalement d'un contenu produit par l'IA depuis l'app, exigé par Google
-- Play pour les apps qui génèrent du contenu (ADR-034). Lus avec le rôle service.
create type public.ai_content_kind as enum ('correction', 'exercise', 'exam');

create table public.ai_content_reports (
  id uuid primary key default gen_random_uuid(),
  -- Gardé sans auteur après la suppression du compte.
  user_id uuid references public.profiles (id) on delete set null,
  kind public.ai_content_kind not null,
  -- Journal corrigé, exercice ou simulation d'examen signalé.
  target_id uuid not null,
  comment text check (char_length(comment) <= 500),
  created_at timestamptz not null default now()
);

create index ai_content_reports_user_created_idx
  on public.ai_content_reports (user_id, created_at);

alter table public.ai_content_reports enable row level security;
revoke all on table public.ai_content_reports from anon, authenticated;

-- Signale un contenu reçu par l'utilisateur connecté : sa correction, sa simulation
-- d'examen ou un exercice. Au plus 20 signalements par jour.
create function public.report_ai_content(
  p_kind public.ai_content_kind,
  p_target_id uuid,
  p_comment text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id constant uuid := (select auth.uid());
  v_is_known boolean;
begin
  -- Le contenu doit exister et appartenir à l'utilisateur, sauf un exercice (partagé).
  v_is_known := case p_kind
    when 'exercise' then exists (select 1 from public.exercises where id = p_target_id)
    when 'exam' then exists (
      select 1 from public.exams where id = p_target_id and user_id = v_user_id)
    else exists (
      select 1 from public.journal_entries where id = p_target_id and user_id = v_user_id)
  end;
  if not v_is_known then
    raise exception 'unknown content' using errcode = 'P0002';
  end if;

  if (select count(*) from public.ai_content_reports
       where user_id = v_user_id and created_at > now() - interval '1 day') >= 20 then
    raise exception 'too many reports' using errcode = 'P0001';
  end if;

  insert into public.ai_content_reports (user_id, kind, target_id, comment)
  values (v_user_id, p_kind, p_target_id, nullif(btrim(left(p_comment, 500)), ''));
end;
$$;

revoke execute on function public.report_ai_content(public.ai_content_kind, uuid, text)
  from public, anon;
grant execute on function public.report_ai_content(public.ai_content_kind, uuid, text)
  to authenticated;
