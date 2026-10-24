# Estudio 3.14 — Hoja de ruta integral
**Actualización: octubre de 2026.** Plan de trabajo; no representa software completado ni autoriza cobros.

## Regla de ejecución
Se implementan directamente las mejoras técnicas no destructivas que no necesiten aprobación económica, jurídica o de identidad. Para cada entrega: código, permisos, prueba verificable, documentación y separación explícita entre demostración y operaciones reales.

| Orden | Módulo | Resultado verificable | Dependencias / límites |
|---|---|---|---|
| 1 | Registro e identidad | Correo/enlace de acceso, perfil al registrarse, sesiones y recuperación | Prueba real de email pendiente |
| 2 | Admisión y membresías | Matrícula, solicitud, validación administrativa, modalidad independiente de rango | Falta operador administrador autenticado y verificación externa de matrícula |
| 3 | Gobierno institucional | Originarios, dos avales distintos, ascenso 12/24 meses, expediente y resolución | Probar con identidades reales y política definitiva |
| 4 | Centro administrativo | KPIs, bandejas, seguimiento y trazabilidad | Probar cuenta administradora |
| 5 | **Producción de servicios** | Fases de pedido, registro de eventos, control de créditos y cancelación | No abrir ventas sin servicios y precios aprobados |
| 6 | **Catálogo/operaciones** | Fichas individuales, briefs y archivos, responsables, entrega y aprobación | Seguridad de archivos y privacidad profesional |
| 7 | **Marketplace real** | Registro de especialidades/jurisdicción, perfiles públicos verificados, búsqueda, formularios de consulta | Consentimientos y régimen de publicidad legal |
| 8 | **Créditos y suscripciones** | Libro mayor, precio y bolsas por categoría, pagos, renovación, devoluciones y conciliación | Aprobación de costos, impuestos, precios, descuentos y proveedor de pagos |
| 9 | **Promoción y RRSS** | Producción de posts/reels, programación con Metricool, revisión y autorización | Plan Metricool, conexiones OAuth y términos comerciales |
| 10 | **Relación con clientes y CRM** | Contactos, etapas, notificaciones y seguimiento | Protección de información confidencial |
| 11 | **Operación y métricas** | Panel ejecutivo, SLAs, facturación, alertas, reportes, backups y auditoría | Validar política de retención, reportes y costos |
| 12 | **Calidad y lanzamiento** | Pruebas automáticas, mobile, accesibilidad, seguridad, legales, plan de incidentes | Evaluaciones con usuarios y conformidad normativa |

### Prioridades del negocio
- Estudio 3.14 es plataforma/empresa de servicios, **no un estudio jurídico que litiga**.
- Círculo Originario es pertenencia fundacional, **no participación societaria**.
- Un rango institucional no se compra; Titular tras 12 meses y Distinguido tras 24 meses totales, ambos con dos avales Originarios distintos y decisión registrada.
- Las modalidades Solo Plataforma y Plataforma + Créditos son independientes de la categoría.
- Los montos de ARS 100.000/300.000 y créditos actuales son **propuestas ilustrativas**. No habilitar medios de pago ni activar precios sin una aprobación formal.
- La verificación profesional, identidad, autorización de publicación y asignación administrativa no pueden autoconcederse por el cliente.

### Acciones reservadas al titular
1. Confirmación personal de identidad/correo y aprovisionamiento de la primera cuenta administradora.
2. Política de admisiones, términos legales/privacidad y comprobación de matrícula.
3. Precios definitivos, montos de créditos, descuentos y medios de pago.
4. Contratación de herramientas externas, dominio, canales de correo y sus costos.
5. Autorización explícita de publicar materiales reales y abrir la plataforma al público.

## Entrega ejecutada en esta intervención
- **Gestión de pedidos:** `service_order_events`, función protegida `admin_advance_order`, transiciones válidas, historial, devolución completa de créditos al cancelar. UI administrativa y seguimiento para el miembro. Sin automatizar pagos.
- **Marketplace verificable:** `lawyer_directory_profiles`, especialidad/localidad/provincia, autorización explícita de visibilidad, alta/actualización con perfil verificado y vista de búsqueda pública separada de ejemplos ficticios.
- **Reglas de acceso:** políticas separadas para visitantes y miembros, comprobación satisfactoria de SELECT público sin sesión, sin permitir altas anónimas en directorio.
- **Base de datos:** 11 migraciones en total, 11 tablas públicas con RLS habilitado; ninguna ficha profesional publicada, pedido real ni cuenta existente durante la revisión.
- **Código:** cuatro bloques JavaScript superaron revisión de sintaxis. No se ha completado una prueba end-to-end con cuenta real (requiere identidad/administrador y material autorizado).
- **Siguientes desarrollos no bloqueados:** formularios detallados para briefs de servicios y flujo de materiales; métricas de entregas; mejoras de búsqueda y accesibilidad; pruebas de RLS con perfiles sintéticos controlados. Los datos confidenciales de expedientes no deben incorporarse a material de ensayo.

**No pendientes para pedir autorización individual:** escritura de código, migraciones no destructivas, pruebas, mejoras de interfaz y documentación. Se consulta al titular solo por datos de identidad, políticas comerciales, decisiones jurídicas o contrataciones con costo.

## Entrega adicional — colaboración y materiales por pedido
- **Base real:** migraciones `20261023_012_order_collaboration.sql` y `20261023_013_order_file_registry.sql`; 13 migraciones y 13 tablas públicas con RLS.
- **Brief:** formulario de objetivo e indicaciones en `Mi cuenta`, enviado al procedimiento `request_service`; no hay cargos sin servicios activos, miembros autorizados y créditos.
- **Conversaciones:** `service_order_messages`, lectura por titular y administradores, escritura mediante RPC con validación de rol y clase de mensaje. No se admiten mensajes a pedidos cancelados.
- **Materiales:** bucket `estudio314-order-files` *privado*, 20 MB por archivo, PDF/PNG/JPG/MP4. Ruta por ID de pedido y usuario; acceso restringido por Storage RLS; índice de archivos `service_order_files` visible solo a propietario y administración. Apertura por enlace temporal de 60 segundos.
- **Interfaz:** desde pedidos en área privada y centro administrativo se puede abrir el espacio, registrar mensajes, adjuntar materiales y consultar archivos.
- **Pruebas:** validación de sintaxis JS, confirmación de bucket no público y límites. `anon` no tiene EXECUTE sobre funciones de mensajes y archivos y se verificó denegación de SELECT anónimo para tabla de mensajes.
- **Advertencia:** falta prueba funcional con dos cuentas reales (abogado y operador), incluyendo permisos de Storage, carga/descarga, verificación de MIME, manejo de errores y políticas de retención. **No subir expedientes jurídicos reales ni información sensible hasta completar esta revisión y la documentación legal.**
- **Seguridad pendiente:** el analizador Supabase mantiene avisos generales por RPCs `SECURITY DEFINER` ejecutables por usuarios autenticados. Deben revisarse con pruebas de roles antes de apertura comercial.

## CRM privado y seguimiento — entrega
- Migración `20261023_014_crm_private_pipeline.sql` aplicada; total **14 migraciones**, **15 tablas públicas**, todas con RLS.
- `crm_opportunities`: alias, área, canal opcional, estado, próxima tarea y fecha; `crm_opportunity_events`: historial de cambios.
- Los datos pertenecen al abogado verificado; ni una cuenta anónima ni una cuenta de otro abogado pueden consultar oportunidades. El panel administrativo no recibe acceso automático a esos datos.
- `create_crm_opportunity` y `advance_crm_opportunity` validan en servidor el estado de la cuenta y la propiedad de las oportunidades. Los usuarios no tienen permisos de escritura directa sobre las tablas.
- `Mi cuenta` incluye altas, avance de etapas, recordatorios por fecha, conteos de oportunidades activas/vencidas e historial; no envía automáticamente correos ni mensajes a potenciales clientes.
- Seguridad comprobada: `anon` carece de SELECT/EXECUTE sobre el CRM; `authenticated` carece de INSERT directo; RLS evita lecturas sin identidad. Pendiente validar con dos usuarios reales diferentes.
- Se mantienen advertencias del auditor sobre RPCs `SECURITY DEFINER` accesibles a usuarios autenticados, sujetas a condiciones internas de autorización. Requieren pruebas completas antes del lanzamiento.

## Bloque ejecutado: recordatorios CRM y métricas operativas
- Migración `20261023_015_crm_reminders.sql` aplicada en Supabase. Se agrega `my_crm_digest()` como función **SECURITY INVOKER** con RLS y datos exclusivamente de `auth.uid()`, más índice parcial de vencimientos.
- En `Mi cuenta`, el CRM ahora muestra recordatorios vencidos, para hoy y próximos siete días, calculados sobre el total de oportunidades del abogado; una lista priorizada ofrece hasta 12 eventos.
- Exportación CSV voluntaria de **hasta 1.000** oportunidades del titular, con escapado de fórmulas para hojas de cálculo. El usuario debe custodiar el archivo descargado.
- El Centro de Administración presenta admisiones, ascensos y pedidos abiertos con más de siete días, además del total histórico de pedidos entregados. No accede a los CRM privados de los abogados.
- **No hay envío proactivo de correos/WhatsApp**: recordatorios in-app al abrir o actualizar el panel, evitando envíos sin consentimiento y dependencias externas.
- Verificaciones: 15 tablas públicas con RLS; una sesión autenticada sin identidad ve 0 filas de CRM; `anon` sin `EXECUTE` de `my_crm_digest()` y sin SELECT al CRM; `authenticated` sin UPDATE directo; scripts JavaScript sin errores de sintaxis.
- **Pendientes importantes:** alta de la primera cuenta administradora por vía segura; pruebas de navegación, registro y permisos entre dos cuentas reales; auditoría de todas las funciones `SECURITY DEFINER`; privacidad/consentimientos antes de datos jurídicos sensibles; ajustar día de corte a zona horaria comercial formal si se automatizan avisos.

## Preparación para pruebas del 24 de octubre de 2026
- Migración `20261023_016_directory_experience_role_checks.sql` aplicada (16 migraciones; 15 tablas públicas con RLS).
- Restricciones endurecidas en `is_platform_admin(p_user)` e `is_active_originario(p_user)`: las llamadas solo responden afirmativamente cuando `p_user = auth.uid()`. Las funciones servidoras siguen consultando el rol de su actor autenticado.
- Marketplace: búsqueda por nombre, especialidad, provincia, localidad y experiencia declarada; se limita a los primeros 200 perfiles ordenados por nombre, con advertencia si se alcanza ese límite. El filtro de experiencia excluye perfiles que no la declaren. Campo autogestionado de años 0–75, sin presentarlo como experiencia certificada.
- Administración: padrón privado con búsqueda y filtros de perfiles verificados/no verificados, hasta los 150 registros más recientes. La bandeja de solicitudes sigue exigiendo comprobación y fundamento para aprobar.
- **Pruebas ejecutadas:** dos bloques JS analizados sin errores; `anon` consulta el directorio público sin fallo (cero perfiles autorizados); sesión SQL con JWT simulado y rol `authenticated` no puede consultar afiliaciones ajenas ni descubrir si terceros son administradores u Originarios, y no ve filas de padrón, solicitudes o CRM (aún sin usuarios).
- **Limitaciones:** no hay cuentas ni datos de ensayo para validar RLS entre dos identidades existentes, flujo completo de admisiones, email, cargas, créditos y producción. Auditor Supabase conserva advertencias de funciones `SECURITY DEFINER` ejecutables por usuarios autenticados (deben analizarse por función), más una tabla administrativa con RLS sin policy intencional.
- **Pruebas manuales prioritarias para mañana:** 1) abrir web e iniciar sesión mediante correo; 2) verificar que se creó perfil; 3) comprobar envío de admisión; 4) autorizar primera cuenta admin mediante procedimiento controlado; 5) verificar que miembros no pueden abrir el padrón; 6) confirmar que el directorio no muestra abogados no verificados ni datos privados. No compartir contraseñas ni expedientes reales.

## Rediseño de acceso, área privada y compra de créditos — 24/10/2026
- Acceso por correo como opción principal. Solicitud enviada con confirmación visual y contraseña bajo un desplegable secundario.
- Tras el evento `SIGNED_IN` Supabase, navegación automática a `Mi cuenta`, sin exigir otro clic. El callback conserva la URL aprobada por Supabase.
- Panel privado organizado en pestañas Resumen, Membresía, Servicios, Comprar créditos, CRM, Perfil público y Administración. El resumen tiene accesos rápidos y tarjetas; la administración sigue condicionada al rol real del servidor.
- Modelo comercial actualizado: **los créditos se compran en Mercado Pago**, no se piden asignaciones ni autorizaciones manuales para cada compra. Se requiere comprobación automática real del pago y conciliación de la intención con el miembro.
- Migraciones `20261024_017_mp_credit_purchases.sql`, `018_mp_checkout_intents.sql`, `019_mp_atomic_credit.sql`, `020_mp_price_snapshot.sql`. Dos Edge Functions desplegadas: `create-credit-checkout` (JWT) y `mercadopago-credit-webhook` (verificación HMAC, sin JWT).
- **Estado de activación:** NO hay credenciales de Mercado Pago, paquetes/precios, pagos ni compras activas; hay que aprobar precios y realizar ensayos antes de activar. Documentado en `docs/MERCADO-PAGO.md`.
- Código HTML/JS comprobado sintácticamente. Pendientes pruebas de UX en navegador (especialmente retorno del magic link, móvil y visibilidad de pestañas), pagos reales, notificaciones, reembolsos y cierre legal.

- **Refinamiento final del panel:** el Centro de Administración se subdivide en Resumen, Miembros, Pedidos y Admisiones y ascensos; las consultas a Supabase conservan sus permisos existentes. Debe probarse la navegación visual desde una cuenta administradora real.

## Entrega: página comercial de membresías y programa independiente de formación (24/10/2026)
- `Membresías` reorganizada como landing visual, con dos proposiciones: **Conexión a plataforma y gestión** (acceso al marketplace, herramientas y comunidad) y **Membresía de crecimiento profesional** (la plataforma más créditos y servicios a demanda). No se publicaron precios ficticios.
- **Trayectoria visible** en tarjeta de perfil. Requisitos, categorías, permanencia y avales trasladados a sección propia `Trayectoria` con detalle desplegable. No se confunde rango institucional con modalidad comercial.
- `Estudiantes` ahora es una landing específica `#formacion`: universidad, año, materias aprobadas, estado curricular, rama jurídica, disponibilidad, motivación y CV PDF hasta 5 MB. La postulación exige inicio de sesión y consentimiento expreso; no equivale a contratación ni habilita ejercicio profesional.
- Supabase: migración `20261024_021_student_applications.sql`, tabla `student_applications` con RLS, funciones de postulación y registro de CV; bucket privado `estudio314-student-cvs` con control de titular y administración; bandeja administrativa con enlaces firmados de 60 segundos.
- `Olvidé mi contraseña` corregido: recuperación visible desde el acceso principal, correo propio independiente del formulario oculto y modo `PASSWORD_RECOVERY` que mantiene visible la entrada de nueva contraseña.
- **Verificado:** 19 tablas públicas con RLS, bucket de CV privado, `anon` sin poder invocar registro de CV, sintaxis de 2 scripts OK; **pendiente:** prueba con correo real de recuperación, envío de postulación, carga/lectura PDF y QA móvil.

## Entrega: evaluación y seguimiento de estudiantes — 24/10/2026
- Migración `20261024_022_student_reviews.sql`: eventos auditables por postulación, estados `recibida → en_revision / contactado / cerrada`, RPC de evaluación solo para administrador, control de cambios y fundamento de 10–600 caracteres.
- Migración `20261024_023_student_review_privacy.sql`: notas de evaluación interna exclusivamente legibles por administradores; postulación y CV bloqueados para edición del estudiante una vez iniciada la revisión.
- Administración: bandeja de Formación con filtro de estados, tarjetas con datos curriculares, sección desplegable para motivación, botón para abrir CV privado y campo de fundamento para cada decisión.
- Estudiante: consulta de su estado desde la landing de Formación; sin acceso a notas administrativas ni seguimiento interno.
- **Pruebas verificadas en SQL con rollback:** creación de postulación, autorización de cuenta admin, imposibilidad de aprobación con cuenta común, visibilidad del estado, ocultamiento de auditoría al aspirante y rechazo de modificación curricular durante la revisión. No se guardaron datos de ensayo.
- **Pendiente** para producción: prueba desde navegador con PDF real no sensible; políticas de retención, eliminación de CV y privacidad estudiantil; revisión legal/laboral del programa antes de aceptar candidatos externos; comunicación de estado mediante canales autorizados, si se decide implementarla.

## Catálogo visual y seguimiento de servicios — entrega 24/10/2026
- Catálogo demostrativo con tarjetas visuales, búsqueda por texto y filtro por categoría; sigue etiquetado como **ilustrativo**, sin cobros.
- Catálogo real `service_catalog`: tarjetas con categoría opcional (`scope.category`), filtros, descripción y costo de créditos vigente. Ficha de servicio con `scope.includes`, `scope.requires`, `scope.excludes` cuando estén informados. Si esos campos faltan, la pantalla lo indica y no inventa entregables.
- Pedido real: ficha/brief por objetivo, consulta del saldo en servidor y resumen de costo y créditos disponibles antes de confirmar. Saldo insuficiente bloquea la confirmación y ofrece acceso a la billetera. La RPC `request_service` sigue haciendo la reserva atómica con bloqueo del miembro.
- Seguimiento: pedidos en tarjetas con etapas Solicitada → En revisión → En proceso → Entregada; cancelaciones diferenciadas; acceso a historial, mensajes y archivos.
- Verificaciones: funciones JavaScript compiladas sin errores, 20 tablas públicas con RLS, 0 servicios reales en el catálogo (sin precios aprobados, por lo que la contratación sigue inactiva). No se insertaron precios ni servicios ficticios en Supabase.
- Próximos bloqueos comerciales: acordar la ficha final, alcance y costo real de cada servicio, pruebas entre operador y miembro, carga de un primer servicio aprobado y Mercado Pago en entorno de prueba.

## Catálogo comercial: fichas en borrador privadas (24/10/2026)
- Nueva migración `20261024_024_service_drafts.sql`, aplicada. Tabla `service_catalog_drafts` con RLS, visible solo al administrador mediante `is_platform_admin(auth.uid())`; escritura a través de RPC `save_service_catalog_draft` con controles de autorización y tamaño de datos.
- Se importaron **8 fichas preliminares** del catálogo de demostración: contenido visual, video/reel, programación de redes, paquete combinado, WhatsApp Business, Meta Ads, organización de consultas/CRM y consultoría de gestión. Se conservaron textos, entregables, requisitos y exclusiones para revisión editorial.
- **No se importaron los créditos ilustrativos** como costos reales. Los ocho `credit_cost` permanecen nulos y `ready_for_review=false`. No se agregaron servicios activos al catálogo comercial real.
- En `Mi cuenta → Administración → Catálogo` se muestran tarjetas con un editor para nombre, categoría, descripción, incluye, necesita del cliente, exclusiones, créditos propuestos y observaciones internas. Guardar no publica ni habilita cobros.
- Comprobaciones reales: cuenta administradora ve 8 fichas; usuario no administrador ve 0; RPC de edición con identidad administradora funciona dentro de transacción revertida; 0 precios reales, 0 fichas aprobadas. Scripts frontend sintácticamente válidos.
- Siguiente paso de decisión comercial: fijar créditos y alcances de cada servicio, definir SLA/plazos, número de revisiones, requisitos de aprobación de cliente y política de cambios. Solo después activar servicios reales y ensayar pedidos de extremo a extremo.
