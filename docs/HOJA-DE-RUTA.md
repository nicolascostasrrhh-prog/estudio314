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
