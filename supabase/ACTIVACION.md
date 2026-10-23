# Activar cuentas reales — Estudio 3.14

## Estado actual (octubre 2026)
La web está en GitHub Pages y muestra **Mi cuenta**. Sin configurar Supabase, los controles reales se mantienen deshabilitados. Los módulos de créditos/avales del prototipo siguen siendo simulaciones locales.

## Conexión paso a paso (solo propietario)

1. Abrí [Supabase](https://supabase.com/dashboard) y creá un proyecto bajo tu cuenta o tu organización. Elegí una contraseña de base de datos fuerte; **no la subas a GitHub ni la pegues en conversaciones**.
2. En Supabase, abrí **SQL Editor** y ejecutá, en orden, el contenido de estos archivos del repositorio:
   - `supabase/migrations/20261023_001_initial.sql`
   - `supabase/migrations/20261023_002_service_credits.sql`
   - `supabase/migrations/20261023_003_signup_profile.sql`
   **Advertencia:** son migraciones nuevas, sin pruebas de integración ejecutadas. Validalas primero en un proyecto de ensayo. No ejecutar sin revisar el resultado de cada paso.
3. En **Authentication → Providers → Email**, configurá el correo/contraseña y verificaciones requeridas.
4. En **Authentication → URL Configuration**, configurá la URL principal:
   `https://nicolascostasrrhh-prog.github.io/estudio314/`
   y agregá esa misma dirección a las URLs de redirección admitidas.
5. En Supabase → **Project Settings → API Keys** (la ubicación exacta puede variar), copiá solamente:
   - Project URL (`https://...supabase.co`)
   - **Publishable key** (`sb_publishable_...`) o **anon/public key** si tu proyecto la utiliza.
   **Nunca copiar la secret key, service_role ni credenciales privadas.**
6. En GitHub → **nicolascostasrrhh-prog/estudio314 → config.js → Edit**, completá los campos `url` y `publishableKey`. Son datos diseñados para ser públicos; su seguridad depende de RLS.
7. GitHub Pages republica automáticamente el cambio. Probá **Mi cuenta → Crear cuenta** con un correo tuyo de ensayo, verificá email e ingresá.
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
