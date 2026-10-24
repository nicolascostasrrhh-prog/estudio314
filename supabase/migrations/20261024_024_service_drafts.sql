begin;
create table public.service_catalog_drafts(
 id uuid primary key default gen_random_uuid(),
 code text not null unique check(char_length(code) between 3 and 80),
 title text not null check(char_length(btrim(title)) between 5 and 140),
 category text not null check(char_length(btrim(category)) between 3 and 90),
 summary text not null check(char_length(btrim(summary)) between 8 and 900),
 scope jsonb not null default '{}'::jsonb check(jsonb_typeof(scope)='object'),
 credit_cost integer check(credit_cost between 1 and 100000),
 review_note text not null default '' check(char_length(review_note)<=1200),
 ready_for_review boolean not null default false,
 linked_service_id uuid unique references public.service_catalog(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
alter table public.service_catalog_drafts enable row level security;
revoke all on public.service_catalog_drafts from public,anon,authenticated;
grant select on public.service_catalog_drafts to authenticated;
create policy service_drafts_admin_read on public.service_catalog_drafts for select to authenticated using(public.is_platform_admin((select auth.uid())));
create function public.save_service_catalog_draft(p_id uuid,p_title text,p_category text,p_summary text,p_scope jsonb,p_credit_cost integer,p_note text,p_ready boolean)
returns void language plpgsql security definer set search_path=''
as $fn$
declare actor uuid:=auth.uid(); current public.service_catalog_drafts%rowtype;
begin
 if actor is null or not public.is_platform_admin(actor) then raise exception 'Solo administración autorizada';end if;
 if p_id is null or length(btrim(coalesce(p_title,''))) not between 5 and 140
  or length(btrim(coalesce(p_category,''))) not between 3 and 90
  or length(btrim(coalesce(p_summary,''))) not between 8 and 900
  or p_scope is null or jsonb_typeof(p_scope)<>'object' or pg_column_size(p_scope)>16000
  or (p_credit_cost is not null and p_credit_cost not between 1 and 100000)
  or length(coalesce(p_note,''))>1200 or p_ready is null
 then raise exception 'Datos del borrador inválidos';end if;
 select * into current from public.service_catalog_drafts where id=p_id for update;
 if not found then raise exception 'Borrador no encontrado';end if;
 if current.linked_service_id is not null then raise exception 'Borrador vinculado a catálogo real, modificar mediante procedimiento autorizado';end if;
 update public.service_catalog_drafts set title=btrim(p_title),category=btrim(p_category),
  summary=btrim(p_summary),scope=p_scope,credit_cost=p_credit_cost,
  review_note=btrim(coalesce(p_note,'')),
  ready_for_review=case when p_credit_cost is null then false else p_ready end,
  updated_at=now()
 where id=p_id;
end $fn$;
revoke execute on function public.save_service_catalog_draft(uuid,text,text,text,jsonb,integer,text,boolean) from public,anon;
grant execute on function public.save_service_catalog_draft(uuid,text,text,text,jsonb,integer,text,boolean) to authenticated;
insert into public.service_catalog_drafts(code,title,category,summary,scope,review_note,ready_for_review)
values('draft-service-01','Contenido visual para historias y feed','Contenido y presencia','4 contenidos visuales para redes',
'{"category":"Contenido y presencia","includes":["Hasta 4 contenidos estáticos adaptados a feed o historias","Diseño acorde a la identidad del abogado","Copys breves y una ronda de ajustes","Archivos finales listos para publicar"],"requires":["Temas o mensajes principales","Logo, colores y referencias disponibles","Redes y público al que va dirigido"],"excludes":"No incluye publicación, gestión mensual de redes ni pauta."}'::jsonb,
'Ficha migrada desde catálogo demostrativo. Falta revisión de alcance, entregables, exclusiones y definición comercial de créditos. Los 5 créditos de la demostración NO se trasladaron como precio real.',false)
on conflict(code) do nothing;
insert into public.service_catalog_drafts(code,title,category,summary,scope,review_note,ready_for_review)
values('draft-service-02','Video o reel para redes','Contenido y presencia','Video vertical de hasta 30 segundos',
'{"category":"Contenido y presencia","includes":["Un video vertical de hasta 30 segundos","Edición, rótulos y audio con licencias adecuadas","Imágenes o videos propios o material generado con IA autorizado","Una ronda de cambios y archivo final"],"requires":["Objetivo y tema","Fotos o videos propios si quiere utilizarlos","Preferencia por material propio o visuales con IA","Estilo, mensaje y referencias"],"excludes":"No incluye filmación, clonación de imagen o voz, campañas ni publicación."}'::jsonb,
'Ficha migrada desde catálogo demostrativo. Falta revisión de alcance, entregables, exclusiones y definición comercial de créditos. Los 8 créditos de la demostración NO se trasladaron como precio real.',false)
on conflict(code) do nothing;
insert into public.service_catalog_drafts(code,title,category,summary,scope,review_note,ready_for_review)
values('draft-service-03','Programación y publicación de posts y reels','Contenido y presencia','Hasta 4 publicaciones aprobadas en un máximo de 2 redes de un estudio.',
'{"category":"Contenido y presencia","includes":["Programación de hasta 4 posts, carruseles o reels previamente terminados y aprobados","Publicación en un máximo de 2 redes sociales vinculadas del mismo estudio jurídico","Configuración de fechas, horarios, textos y portadas suministrados","Revisión del estado de programación y confirmación de publicaciones cuando la red lo permita","Resumen de enlaces y estado de publicación del período"],"requires":["Contenido final aprobado: imágenes o videos y textos","Redes elegidas, fechas y horarios de publicación","Autorización para conectar las cuentas profesionales a la herramienta de gestión","Aprobación expresa del abogado antes de programar o publicar"],"excludes":"No incluye creación o edición de contenidos, community management, atención de mensajes, pauta publicitaria ni publicaciones adicionales. La publicación efectiva depende de permisos y límites de cada red. Integración con Metricool pendiente."}'::jsonb,
'Ficha migrada desde catálogo demostrativo. Falta revisión de alcance, entregables, exclusiones y definición comercial de créditos. Los 4 créditos de la demostración NO se trasladaron como precio real.',false)
on conflict(code) do nothing;
insert into public.service_catalog_drafts(code,title,category,summary,scope,review_note,ready_for_review)
values('draft-service-04','Contenido y publicación para redes','Contenido y presencia','Paquete integral: 4 contenidos visuales y su programación/publicación.',
'{"category":"Contenido y presencia","includes":["Producción de hasta 4 contenidos visuales estáticos para feed o historias (según formatos compatibles)","Adaptación a la identidad profesional y textos breves","Una ronda de ajustes y aprobación previa","Programación/publicación de hasta 4 contenidos aprobados en un máximo de 2 redes vinculadas","Resumen de publicaciones realizadas"],"requires":["Temas, mensajes y tono institucional del estudio","Logo e identidad gráfica, si existe","Redes de destino y fechas preferidas","Autorización de conexión y aprobación del contenido final"],"excludes":"No incluye producción de reels en video, atención de comunidad, pauta ni publicaciones adicionales. La herramienta de programación se integrará en otra etapa."}'::jsonb,
'Ficha migrada desde catálogo demostrativo. Falta revisión de alcance, entregables, exclusiones y definición comercial de créditos. Los 9 créditos de la demostración NO se trasladaron como precio real.',false)
on conflict(code) do nothing;
insert into public.service_catalog_drafts(code,title,category,summary,scope,review_note,ready_for_review)
values('draft-service-05','Configuración de WhatsApp Business','Atención y captación','Puesta a punto del canal de atención',
'{"category":"Atención y captación","includes":["Configuración del perfil comercial, datos y horarios","Mensaje de bienvenida y ausencia","Hasta cinco respuestas rápidas","Hasta cinco etiquetas de organización","Guía de uso y una revisión final"],"requires":["Número autorizado y acceso del titular","Nombre comercial, especialidad y horarios","Datos de contacto y responsable de responder"],"excludes":"No incluye WhatsApp API, chatbot avanzado ni atención administrada por Estudio 3.14."}'::jsonb,
'Ficha migrada desde catálogo demostrativo. Falta revisión de alcance, entregables, exclusiones y definición comercial de créditos. Los 7 créditos de la demostración NO se trasladaron como precio real.',false)
on conflict(code) do nothing;
insert into public.service_catalog_drafts(code,title,category,summary,scope,review_note,ready_for_review)
values('draft-service-06','Campaña Meta Ads','Atención y captación','Gestión básica de una campaña; pauta adicional',
'{"category":"Atención y captación","includes":["Configuración de un objetivo y público geográfico","Una campaña con un conjunto de anuncios","Una creatividad publicitaria inicial","Seguimiento básico y resumen de resultados"],"requires":["Objetivo, localidad y público","Presupuesto de pauta, días y fecha inicial","Cuenta publicitaria y destino de consultas","Aprobación del anuncio"],"excludes":"La pauta consume créditos aparte. No garantiza consultas ni clientes."}'::jsonb,
'Ficha migrada desde catálogo demostrativo. Falta revisión de alcance, entregables, exclusiones y definición comercial de créditos. Los 15 créditos de la demostración NO se trasladaron como precio real.',false)
on conflict(code) do nothing;
insert into public.service_catalog_drafts(code,title,category,summary,scope,review_note,ready_for_review)
values('draft-service-07','Organización de consultas y CRM','Atención y captación','Circuito administrativo de recepción y seguimiento',
'{"category":"Atención y captación","includes":["Diseño de hasta cinco estados de seguimiento","Campos esenciales de contactos y origen","Plantilla operativa y capacitación breve"],"requires":["Canales actuales de consultas","Responsables de seguimiento","Etapas y dificultades que desean mejorar"],"excludes":"No incluye migración masiva ni desarrollo de software a medida."}'::jsonb,
'Ficha migrada desde catálogo demostrativo. Falta revisión de alcance, entregables, exclusiones y definición comercial de créditos. Los 9 créditos de la demostración NO se trasladaron como precio real.',false)
on conflict(code) do nothing;
insert into public.service_catalog_drafts(code,title,category,summary,scope,review_note,ready_for_review)
values('draft-service-08','Consultoría de gestión del estudio','Gestión y desarrollo','Diagnóstico sobre una necesidad de gestión',
'{"category":"Gestión y desarrollo","includes":["Reunión de hasta 60 minutos","Análisis de un desafío organizacional","Documento breve con recomendaciones"],"requires":["Problema prioritario y objetivo","Datos operativos pertinentes no confidenciales"],"excludes":"No incluye asesoramiento jurídico ni ejecución posterior del proyecto."}'::jsonb,
'Ficha migrada desde catálogo demostrativo. Falta revisión de alcance, entregables, exclusiones y definición comercial de créditos. Los 8 créditos de la demostración NO se trasladaron como precio real.',false)
on conflict(code) do nothing;
commit;