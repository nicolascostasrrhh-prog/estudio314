begin;
create type public.crm_stage as enum ('nuevo','contactado','reunion','propuesta','ganado','cerrado');
create table public.crm_opportunities (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null references auth.users(id) on delete cascade,
 contact_alias text not null check(char_length(btrim(contact_alias)) between 2 and 120),
 practice_area text not null check(char_length(btrim(practice_area)) between 2 and 120),
 contact_method text not null default '' check(char_length(contact_method)<=160),
 stage public.crm_stage not null default 'nuevo',
 next_action text not null default '' check(char_length(next_action)<=280),
 follow_up_on date,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index crm_opportunities_owner_stage on public.crm_opportunities(owner_id,stage);
create index crm_opportunities_owner_followup on public.crm_opportunities(owner_id,follow_up_on);
alter table public.crm_opportunities enable row level security;
revoke all on public.crm_opportunities from public,anon,authenticated;
grant select on public.crm_opportunities to authenticated;
create policy crm_owner_read on public.crm_opportunities for select to authenticated using(owner_id=(select auth.uid()));

create table public.crm_opportunity_events(
 id bigint generated always as identity primary key,
 opportunity_id uuid not null references public.crm_opportunities(id) on delete cascade,
 actor_id uuid not null references auth.users(id),
 old_stage public.crm_stage,
 new_stage public.crm_stage not null,
 note text not null check(char_length(note) between 5 and 600),
 occurred_at timestamptz not null default now()
);
create index crm_events_opportunity_date on public.crm_opportunity_events(opportunity_id,occurred_at desc);
alter table public.crm_opportunity_events enable row level security;
revoke all on public.crm_opportunity_events from public,anon,authenticated;
grant select on public.crm_opportunity_events to authenticated;
create policy crm_event_owner_read on public.crm_opportunity_events for select to authenticated
using(exists(select 1 from public.crm_opportunities c where c.id=opportunity_id and c.owner_id=(select auth.uid())));

create function public.create_crm_opportunity(p_alias text,p_area text,p_method text,p_next text,p_followup date)
returns uuid language plpgsql security definer set search_path=''
as $fn$
declare v_user uuid:=auth.uid(); v_id uuid;
begin
 if v_user is null or not exists(select 1 from public.member_profiles
 where user_id=v_user and active and is_verified and category in ('asociado','titular','distinguido','originario'))
 then raise exception 'Se requiere cuenta profesional verificada'; end if;
 if char_length(btrim(coalesce(p_alias,''))) not between 2 and 120 or
 char_length(btrim(coalesce(p_area,''))) not between 2 and 120 or
 char_length(coalesce(p_method,''))>160 or char_length(coalesce(p_next,''))>280
 then raise exception 'Revisá los datos del contacto'; end if;
 insert into public.crm_opportunities(owner_id,contact_alias,practice_area,contact_method,next_action,follow_up_on)
 values(v_user,btrim(p_alias),btrim(p_area),btrim(coalesce(p_method,'')),btrim(coalesce(p_next,'')),p_followup)
 returning id into v_id;
 insert into public.crm_opportunity_events(opportunity_id,actor_id,new_stage,note)
 values(v_id,v_user,'nuevo','Oportunidad creada en el CRM');
 return v_id;
end $fn$;

create function public.advance_crm_opportunity(p_id uuid,p_stage public.crm_stage,p_next text,p_followup date,p_note text)
returns void language plpgsql security definer set search_path=''
as $fn$
declare v_user uuid:=auth.uid(); v_current public.crm_opportunities%rowtype;
begin
 if v_user is null then raise exception 'Iniciá sesión'; end if;
 if p_stage is null or char_length(btrim(coalesce(p_note,''))) not between 5 and 600 or char_length(coalesce(p_next,''))>280
 then raise exception 'Datos de seguimiento inválidos'; end if;
 select * into v_current from public.crm_opportunities where id=p_id and owner_id=v_user for update;
 if not found then raise exception 'No existe una oportunidad propia con ese identificador'; end if;
 if v_current.stage in ('ganado','cerrado') then raise exception 'Este contacto está cerrado'; end if;
 update public.crm_opportunities set stage=p_stage,next_action=btrim(coalesce(p_next,'')),
 follow_up_on=p_followup,updated_at=now() where id=p_id and owner_id=v_user;
 insert into public.crm_opportunity_events(opportunity_id,actor_id,old_stage,new_stage,note)
 values(p_id,v_user,v_current.stage,p_stage,btrim(p_note));
end $fn$;

revoke execute on function public.create_crm_opportunity(text,text,text,text,date) from public,anon;
revoke execute on function public.advance_crm_opportunity(uuid,public.crm_stage,text,date,text) from public,anon;
grant execute on function public.create_crm_opportunity(text,text,text,text,date) to authenticated;
grant execute on function public.advance_crm_opportunity(uuid,public.crm_stage,text,date,text) to authenticated;
commit;