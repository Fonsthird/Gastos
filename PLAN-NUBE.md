# Plan: datos en la nube (widget, notificaciones y Wallet automático)

La app se queda en GitHub Pages (`fonsthird.github.io/Gastos`), con la misma dirección.
Lo único que cambia es que los datos, que hoy viven solo en el iPhone, también se guardan
en una base de datos en **Supabase** (gratis). Con eso se pueden hacer las tres cosas.

---

## Estado

- [x] Parte 1: proyecto de Supabase creado (`drhsbrauoymkiijucjnt`).
- [x] Parte 2: la app inicia sesión y sincroniza (Ajustes → Cuenta en la nube). Falta correr `supabase/setup.sql`.
- [x] Parte 3: widget de Scriptable (Ajustes → Widget y Wallet → Copiar script del widget).
- [ ] Parte 4: notificaciones — pendiente.
- [x] Parte 5: Wallet sin abrir la app (función `wallet_gasto`; los gastos llegan "por clasificar").

## Parte 1 — Lo que haces tú (unos 15 min)

1. Entra a **supabase.com** y crea una cuenta gratis (puedes entrar con GitHub).
2. Toca **New project**:
   - Nombre: `gastos`
   - Contraseña de la base de datos: invéntala y **guárdala** en tus notas.
   - Región: la más cercana a México (por ejemplo, *East US*).
3. Espera un par de minutos a que se cree.
4. Ve a **Project Settings → API** y copia estos dos datos:
   - **Project URL** (algo como `https://xxxx.supabase.co`)
   - **anon / publishable key** (una clave larga)

   Estos dos se pueden compartir conmigo sin problema.
   **No compartas** la clave que dice **service_role / secret**: esa es privada.
5. En **Authentication → Sign In / Providers**, revisa que **Email** esté activado.

Cuando tengas los dos datos del paso 4, abre una sesión nueva de Claude Code en el repo
`fonsthird/gastos` y dile:
> "Sigue el PLAN-NUBE.md. Aquí están mi Project URL y mi anon key: …"

---

## Parte 2 — Lo que hace Claude: sincronizar los datos

- Crear las tablas (movimientos y configuración) con seguridad por usuario (RLS),
  para que solo tú puedas ver tus datos.
- Agregar a la app un inicio de sesión con tu correo (te llega un enlace, sin contraseña).
- La primera vez, subir todo lo que ya tienes en el teléfono, sin borrar nada.
- Después, cada cambio se guarda en el teléfono y en la nube.

Tú solo: abrir la app, poner tu correo y tocar el enlace que te llega.

---

## Parte 3 — Widget con tus números

1. Instala **Scriptable** (gratis) desde el App Store.
2. Claude te da un script para copiar y pegar en Scriptable. El widget muestra:
   - Cuánto te queda de tu límite semanal
   - Cuánto te falta pagar de la tarjeta para no generar intereses y en cuántos días
3. En la pantalla de inicio: mantén presionado → **Edit → Add Widget → Scriptable**
   → elige el script.

---

## Parte 4 — Notificaciones

- Claude configura en Supabase una revisión diaria que te avisa:
  - 3 días antes y el día de tu **fecha límite de pago**
  - el día de tu **corte**
  - opcional: los viernes, "registra tus viáticos"
- Tú: abrir Gastos **desde el ícono de la pantalla de inicio** → Ajustes →
  **Activar notificaciones** → **Allow**.

---

## Parte 5 — Gastos de Wallet sin abrir la app

- Claude te da una dirección y una clave personal.
- En tu automatización de **Shortcuts** ("When Any Card is tapped") se cambian las acciones:
  en vez de copiar al portapapeles, usa **Get Contents of URL** para mandar el monto y el
  comercio a esa dirección.
- El gasto aparece solo en la app como **"Por clasificar"**; tú solo eliges la categoría
  y quién pagó cuando la abras.

---

## Notas para Claude

- Mantener el guardado local (`localStorage`, clave `gastos-v2`) y sumar Supabase como
  respaldo y sincronización; la app ya tiene la cola `pending` / `pendingDel` y `flush()`
  pensada para un `store` remoto (ver `initStore()` en `index.html`).
- No cambiar la dirección de la app: los datos locales están ligados a ese origen.
- Nunca guardar la service_role key en el repo; las Edge Functions la usan como secreto
  de Supabase.
- Web Push en iOS solo funciona con la app instalada en la pantalla de inicio (iOS 16.4+)
  y necesita un service worker y claves VAPID.
