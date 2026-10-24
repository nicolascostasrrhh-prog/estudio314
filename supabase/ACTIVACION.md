# Activar cuentas reales — Estudio 3.14

## Estado actual (octubre 2026)
**Proyecto activo:** `estudio314` (ref `pdefftaresvglcugzqtz`) en organización `Estudio3.14`, región São Paulo. El 23/10/2026 se aplicaron y verificaron las migraciones `estudio314_initial_schema`, `estudio314_service_credits`, `estudio314_signup_profile` y `estudio314_security_hardening`. La web ya tiene `config.js` configurado con URL y clave **publicable**; el módulo Mi cuenta intenta usar autenticación real. Los otros paneles de créditos y avales siguen siendo demostraciones locales.

## Conexión paso a paso (solo propietario)

1. **Completado:** proyecto Supabase creado bajo la organización Estudio3.14. Nunca subas contraseñas o secretos a GitHub.
2. **Completado:** migraciones ejecutadas y registradas, en orden:
   - `supabase/migrations/20261023_001_initial.sql`
   - `supabase/migrations/20261023_002_service_credits.sql`
   - `supabase/migrations/20261023_003_signup_profile.sql`
   - `supabase/migrations/20261023_004_security_hardening.sql`
   **Verificado:** 8 tablas públicas, RLS activo en las 8, 7 políticas y un trigger de creación de perfiles. No se hicieron pruebas de registro completo por correo.
3. En **Authentication → Providers → Email**, configurá el correo/contraseña y verificaciones requeridas.
4. En **Authentication → URL Configuration**, configurá la URL principal:
   `https://nicolascostasrrhh-prog.github.io/estudio314/`
   y agregá esa misma dirección a las URLs de redirección admitidas.
5. **Completado:** URL del proyecto y clave publicable recuperadas por la conexión autorizada. Si revisás las claves en Supabase → Project Settings → API Keys, solo la publicable puede incluirse en el frontend:
   - Project URL (`https://...supabase.co`)
   - **Publishable key** (`sb_publishable_...`) o **anon/public key** si tu proyecto la utiliza.
   **Nunca copiar la secret key, service_role ni credenciales privadas.**
6. **Completado:** GitHub → nicolascostasrrhh-prog/estudio314 → `config.js` configurado automáticamente. RLS y restricciones de permisos instaladas.
7. **Pendiente:** configurá primero la URL de autenticación del paso 4. Después GitHub Pages mostrará **Mi cuenta** conectada y podrás probar **Mi cuenta → Crear cuenta** con un correo de ensayo, verificarlo e ingresar.
8. Comprobá en Supabase que el usuario existe en **Authentication → Users** y que su perfil aparece en `public.member_profiles` con `is_verified=false`, categoría `asociado` y sin créditos asignados.
9. Habilitá la cuenta profesional y sus beneficios solamente tras completar el proceso de verificación y revisión de seguridad.

## Pruebas de seguridad obligatorias

- Un miembro sin verificar no puede realizar pedidos reales ni solicitar un ascenso.
- Un usuario autenticado no puede cambiar su propia categoría, antigüedad, identidad administrativa ni crédito desde el frontend.
- Originarios de prueba no verificados no pueden emitir avales.
- Dos avales del mismo Originario no cuentan como dos.
- Una postulación no puede aprobarse sin dos avales y decisión administrativa.
- Dos pedidos simultáneos no pueden generar saldo negativo.
- Los perfiles y solicitudes de otros usuarios no deben filtrarse en respuestas API.
- Las claves privadas jamás deben estar expuestas en `config.js`.
- Alta, confirmación y recuperación de contraseña deben comprobarse con el SMTP configurado.

## Límite del MVP conectado
`Mi cuenta` puede crear sesión de Supabase y consultar perfil/saldo **cuando exista un proyecto conectado y migrado**. La verificación de matrícula, panel administrativo real, subida de archivos, pedidos efectivos y corrección de estados requieren más desarrollo. No asumir que la plataforma está lista para usuarios reales antes de completar pruebas y privacidad.

## Separación de categorías y modalidades
- **Asociado → Titular:** desde 12 meses + 2 avales Originarios + resolución.
- **Titular → Distinguido:** desde 24 meses de permanencia total + 2 avales Originarios + resolución.
- Círculo Originario es condición fundacional distinta de la progresión regular.
- Los descuentos y las asignaciones de créditos deben fijarse en un cuadro económico aprobado, no están automatizados todavía.

## Auditoría efectuada en Supabase

- Fecha 23/10/2026: 8 tablas, 4 migraciones, RLS habilitado en todas las tablas.
- Se verificó que `anon` no puede ejecutar el trigger de registro ni hacer TRUNCATE de perfiles. Tampoco el rol `authenticated` puede truncar créditos.
- La auditoría aún informa advertencias sobre funciones `SECURITY DEFINER` autenticadas: son puntos controlados por validaciones de identidad y categoría, pero **requieren pruebas de autorización de extremo a extremo antes de abrir al público**.
- `platform_admins` no tiene política de lectura por diseño: ni usuarios normales ni clientes públicos pueden listar administradores.
- No se han asignado permisos administrativos ni créditos reales a ningún usuario.
