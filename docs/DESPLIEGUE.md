# Guía de despliegue paso a paso

Sigue este orden: **Supabase → GitHub → Vercel → Flutter**. Cada paso depende del anterior.

## 1. Crear el proyecto en Supabase

1. Entra a [supabase.com](https://supabase.com) → crea una cuenta gratuita → **New project**.
2. Elige nombre (ej. `pos-abarrotes`), una contraseña segura de base de datos (guárdala en un lugar seguro) y la región más cercana (South America si está disponible).
3. Cuando el proyecto esté listo, ve a **Project Settings → API** y copia:
   - `Project URL` → será tu `NEXT_PUBLIC_SUPABASE_URL` / `SUPABASE_URL`
   - `anon public` key → será tu `NEXT_PUBLIC_SUPABASE_ANON_KEY` / `SUPABASE_ANON_KEY`
4. Aplica el esquema de base de datos. Opción fácil (sin instalar nada): entra a **SQL Editor** en el panel de Supabase y pega, en orden, el contenido de:
   - `supabase/migrations/0001_schema.sql`
   - `supabase/migrations/0002_rls.sql`
   - `supabase/migrations/0003_triggers.sql`
   - (opcional, solo para pruebas) `supabase/seed/seed.sql`

   Opción con CLI (recomendada a futuro, permite versionar cambios):
   ```bash
   npm install -g supabase
   supabase login
   supabase link --project-ref TU-PROJECT-REF
   supabase db push
   ```
5. **Crea tu primer usuario (tú, como propietaria)**: Authentication → Users → **Add user** → escribe tu correo y una contraseña. Antes de guardar, en "User Metadata" pega (reemplazando el UUID por el `id` real de la fila que insertó `seed.sql` en `tiendas`, o el que tenga tu tienda si la creaste manualmente):
   ```json
   { "tienda_id": "00000000-0000-0000-0000-000000000001", "nombre_completo": "Anabel", "rol": "propietario" }
   ```
   El trigger `manejar_nuevo_usuario` crea tu perfil automáticamente. Repite este paso (con `"rol": "cajero"`) para cada cajero que contrates.
6. En **Authentication → Policies** puedes subir el mínimo de longitud de contraseña a 8-10 caracteres.

## 2. Subir el código a GitHub

Ya tienes un repositorio git inicializado localmente en este proyecto (ver `docs/../` — el commit inicial ya está hecho). Para subirlo:

1. Crea un repositorio vacío en [github.com/new](https://github.com/new) (ej. `pos-abarrotes`). **No** marques "Add README" (ya tenemos uno).
2. Desde tu computadora, en la carpeta del proyecto:
   ```bash
   git remote add origin https://github.com/TU-USUARIO/pos-abarrotes.git
   git branch -M main
   git push -u origin main
   ```

## 3. Desplegar el panel web en Vercel

1. Entra a [vercel.com](https://vercel.com) → **Add New → Project** → importa el repositorio `pos-abarrotes` de GitHub.
2. En **Root Directory**, selecciona `web` (¡importante! el proyecto Next.js vive en la subcarpeta `web/`, no en la raíz del monorepo).
3. Vercel detecta Next.js automáticamente. Antes de darle a "Deploy", agrega las variables de entorno (Environment Variables):
   - `NEXT_PUBLIC_SUPABASE_URL` = la Project URL que copiaste en el paso 1
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = la anon key que copiaste en el paso 1
4. Dale **Deploy**. En 1-2 minutos tendrás una URL pública (`https://pos-abarrotes-xxxx.vercel.app`).
5. Desde ahora, **cada `git push` a `main` despliega automáticamente** una nueva versión — no necesitas volver a tocar Vercel.
6. (Opcional) Conecta un dominio propio en Project Settings → Domains si más adelante compras uno.

## 4. Compilar y preparar la app Flutter

1. Instala Flutter (si no lo tienes): sigue [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) para tu sistema operativo.
2. Verifica que todo esté bien instalado:
   ```bash
   flutter doctor
   ```
3. Dentro de `mobile/`, crea `env.json` (no se sube a git) con tus credenciales reales de Supabase:
   ```json
   {
     "SUPABASE_URL": "https://TU-PROYECTO.supabase.co",
     "SUPABASE_ANON_KEY": "tu-anon-key-publica"
   }
   ```
4. Instala las dependencias y corre la app en un celular Android conectado por USB (con depuración USB activada) o en un emulador:
   ```bash
   cd mobile
   flutter pub get
   flutter run --dart-define-from-file=env.json
   ```
5. Cuando quieras instalar el APK directamente en un celular para uso real (sin cable, sin Play Store):
   ```bash
   flutter build apk --release --dart-define-from-file=env.json
   # el archivo queda en mobile/build/app/outputs/flutter-apk/app-release.apk
   ```
   Pásaselo al celular del mostrador (por USB, WhatsApp Web, o una unidad USB) e instálalo permitiendo "orígenes desconocidos".
6. **Emparejar la ticketera Bluetooth**: empareja la impresora térmica desde los ajustes de Bluetooth del celular (como cualquier dispositivo Bluetooth) antes de abrir la app — la app la detectará como "dispositivo emparejado" para conectarse. Si tu impresora requiere un PIN, el más común es `0000` o `1234`.

## 5. Checklist antes de operar con dinero real

- [ ] Ejecutaste las 3 migraciones SQL en el proyecto de Supabase real (no solo local)
- [ ] Creaste tu usuario propietario y puedes iniciar sesión en el panel web
- [ ] El panel está desplegado en Vercel y accesible por HTTPS
- [ ] Probaste una venta completa en la app (abrir caja → vender → imprimir → cerrar caja)
- [ ] Activaste backups automáticos en Supabase
- [ ] Revisaste `docs/SEGURIDAD.md`

## Problemas comunes

- **"Invalid API key" en el panel o la app**: revisa que copiaste la `anon public` key, no la `service_role` (esa nunca se usa en el cliente).
- **El build de Vercel falla**: casi siempre es porque "Root Directory" no quedó en `web`. Revisa Project Settings → General.
- **La app no imprime**: confirma que el Bluetooth del celular esté encendido y la impresora emparejada; algunas impresoras genéricas necesitan reiniciarse si llevan varios minutos sin usarse.
