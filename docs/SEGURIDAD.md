# Seguridad

Resumen de las medidas ya implementadas en el código y lo que falta configurar tú misma al desplegar (porque depende de tus cuentas/credenciales).

## Ya implementado en el código

**Base de datos (Supabase / Postgres)**
- Row Level Security (RLS) activado en **todas** las tablas de negocio (`supabase/migrations/0002_rls.sql`). Nadie puede leer o escribir datos de una tienda que no es la suya, ni siquiera si alguien consigue la `anon key` — la key pública por sí sola no da acceso a nada sin una sesión autenticada.
- Roles a nivel de base de datos: `propietario` puede administrar catálogo y usuarios; `cajero` solo puede vender y consultar. Esto se aplica en RLS, no solo en la interfaz — aunque alguien manipule el panel web o la app, Postgres rechaza la operación.
- Los movimientos de inventario por venta y la numeración de tickets los genera un trigger `SECURITY DEFINER` en el servidor, no el cliente — nadie puede "inventarse" un número de ticket o manipular el stock directamente.
- Las ventas nunca se borran, solo se anulan (`estado = 'anulada'`), dejando rastro de auditoría.
- Registro de invitación de usuarios cerrado (`enable_signup = false` en `supabase/config.toml`): nadie puede autoregistrarse, solo el propietario invita desde el panel de Supabase.

**Panel web (Next.js)**
- Autenticación con Supabase Auth (email + contraseña), cookies HTTP-only gestionadas por `@supabase/ssr` — el token de sesión nunca queda expuesto a JavaScript en el navegador.
- `middleware.ts` bloquea cualquier ruta del panel si no hay sesión válida, antes de renderizar nada.
- La página de Usuarios verifica el rol en el servidor y redirige si no eres propietario (defensa en profundidad, además de RLS).
- Validación de formularios con `zod` antes de enviar datos a la base de datos.
- Cabeceras de seguridad HTTP (`next.config.mjs`): `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`.
- Ningún secreto en el repositorio: `.env.local` y `mobile/env.json` están en `.gitignore`; solo se sube `.env.example` con placeholders.

**App móvil (Flutter)**
- Las credenciales de Supabase se pasan por `--dart-define-from-file`, nunca hardcodeadas en el código fuente.
- El rol del usuario también se valida en el servidor (RLS) — la app no puede "mentir" sobre quién es.

## Lo que debes configurar tú al desplegar

1. **Contraseñas fuertes** para las cuentas de propietario/cajeros (Supabase Auth exige mínimo 6 caracteres por defecto — súbelo a 8-10 en Authentication → Policies).
2. **Nunca compartas la `service_role key`** de Supabase con nadie ni la pongas en el código del panel o la app — esa key salta TODA la seguridad de RLS. Solo se usaría en el futuro desde una Edge Function si necesitas automatizar invitaciones.
3. **HTTPS**: Vercel y Supabase lo dan automáticamente, no necesitas configurar nada.
4. **Backups**: activa los backups automáticos diarios en Supabase (Settings → Database → Backups) antes de operar con dinero real.
5. **Revisa los logs de Supabase** (Auth → Logs) de vez en cuando para detectar intentos de acceso sospechosos.
6. **Actualiza dependencias** periódicamente (`npm audit`, `flutter pub outdated`) — quedó anotado como tarea recurrente en el organizador.

## Modelo de amenazas (resumen para tu memoria/sustentación)

| Amenaza | Mitigación |
|---|---|
| Cajero intenta editar precios | RLS bloquea `update`/`insert` en `productos` si `rol != propietario` |
| Alguien roba el celular con la app abierta | La sesión expira (`jwt_expiry`); recomienda bloqueo de pantalla del equipo |
| Inyección SQL | Supabase usa consultas parametrizadas vía PostgREST; nunca se concatena SQL a mano |
| Venta con stock insuficiente | El trigger de base de datos la rechaza, sin importar qué cliente la originó |
| Fuga de la `anon key` | Es pública por diseño; la seguridad real la da RLS, no el secreto de la key |
