# Base de datos Estudio 3.14

## Estado

El archivo `supabase/migrations/20261023_001_initial.sql` define el primer esquema PostgreSQL compatible con Supabase. **No está desplegado ni conectado**. Subirlo a GitHub no crea un servidor, usuarios ni credenciales.

## Qué modela

- Identidades de usuarios gestionadas por `auth.users`.
- Miembros y categorías: Asociado, Titular, Distinguido, Círculo Originario y Formación.
- Modalidad comercial: Plataforma o Integral (independiente de la categoría).
- Administradores de plataforma, aprovisionados manualmente por un operador autorizado.
- Solicitudes de ascenso, avales de Originarios distintos, decisión administrativa y auditoría.
- Catálogo de servicios, pedidos, movimientos de créditos e historial.
- Row Level Security para evitar que un miembro modifique su categoría, créditos o decisiones mediante el cliente.

## Reglas implementadas en base de datos

- Asociado → Titular: mínimo **12 meses** de permanencia total.
- Titular → Distinguido: mínimo **24 meses** de permanencia total.
- Los requisitos se vuelven a comprobar al aprobar, además de la postulación.
- Cada aval solo puede emitirlo un **Originario verificado y activo**. Un Originario no puede avalarse a sí mismo.
- Se requieren **dos avales de usuarios distintos**; no son un ascenso automático.
- La aprobación o el rechazo exigen identidad de administrador y fundamento.
- Los eventos quedan registrados en `promotion_audit`. En producción debe reforzarse el registro inmutable y de eventos de seguridad.

Los criterios de méritos, participación, admisión originaria, plazos históricos y descuentos deberán formalizarse en un reglamento.

## Lo que falta antes de usar datos reales

1. Crear proyecto Supabase bajo propiedad del titular de Estudio 3.14.
2. Revisar migración con un entorno de prueba y ejecutar tests de permisos RLS.
3. Aplicar la migración desde consola o CLI con credenciales **nunca compartidas en GitHub**.
4. Desarrollar alta de cuenta, verificación de email, recuperación de acceso y enrolamiento de perfiles con seguridad de servidor.
5. Crear un backend seguro para verificación de matrícula, alta de Originarios y administración.
6. Construir las vistas de postulante, avalista y administrador conectadas a Supabase.
7. Separar contenido institucional público de información privada de perfiles, avales y consultas.
8. Implementar libro mayor de créditos transaccional con reservas, saldos, vencimientos, cancelaciones y trazabilidad.
9. Implementar pagos/suscripciones, custodia de materiales y consentimientos de datos.
10. Auditar privacidad, tratamiento de información sensible y publicidad profesional conforme a la jurisdicción.

## Seguridad y economía

**Nunca** ubicar `service_role`, contraseñas ni secretos en la web pública ni en el repositorio público.

Los créditos en el HTML actual son ficticios y se almacenan solo en el navegador. No otorgan créditos reales ni pueden emplearse como forma de pago.

La bolsa mensual por categoría, los precios y los descuentos son propuestas, no condiciones aprobadas ni facturables.

## API de ascensos prevista

Mediante llamadas RPC autenticadas a PostgreSQL:

- `request_promotion('titular')` o `request_promotion('distinguido')`
- `endorse_promotion(application_uuid, motivo)`
- `decide_promotion(application_uuid, aprobar_boolean, fundamento)` solo administración.

La decisión no puede ser efectuada por la interfaz pública sin autenticación.

## Contratación de servicios

Las solicitudes reales deben tener una capa de servidor para bloquear créditos de forma atómica, registrar el costo en el libro mayor, validar permisos y coordinar entregas. **No permitir que el frontend inserte saldos, ajustes o pedidos sin transacción validada**.
