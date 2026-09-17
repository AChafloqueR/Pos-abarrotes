-- ============================================================================
-- POS Abarrotes — 0002_rls.sql
-- Seguridad a nivel de fila (RLS). Regla de oro: TODA tabla con datos de
-- negocio tiene RLS activado y nadie ve datos de una tienda que no es la suya.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Funciones auxiliares (SECURITY DEFINER para poder leer perfiles sin recursión)
-- ---------------------------------------------------------------------------
create or replace function public.tienda_actual()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select tienda_id from public.perfiles where id = auth.uid();
$$;

create or replace function public.rol_actual()
returns public.rol_usuario
language sql
security definer
stable
set search_path = public
as $$
  select rol from public.perfiles where id = auth.uid();
$$;

create or replace function public.es_propietario()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((select rol from public.perfiles where id = auth.uid()) = 'propietario', false);
$$;

-- ---------------------------------------------------------------------------
-- Activar RLS
-- ---------------------------------------------------------------------------
alter table public.tiendas enable row level security;
alter table public.perfiles enable row level security;
alter table public.categorias enable row level security;
alter table public.productos enable row level security;
alter table public.movimientos_inventario enable row level security;
alter table public.cajas enable row level security;
alter table public.ventas enable row level security;
alter table public.detalle_venta enable row level security;
alter table public.contadores_ticket enable row level security;

-- ---------------------------------------------------------------------------
-- tiendas: cada usuario solo ve su propia tienda
-- ---------------------------------------------------------------------------
create policy "tiendas_select_propia" on public.tiendas
  for select using (id = public.tienda_actual());

create policy "tiendas_update_propietario" on public.tiendas
  for update using (id = public.tienda_actual() and public.es_propietario());

-- ---------------------------------------------------------------------------
-- perfiles: ver compañeros de la misma tienda; solo el propietario administra
-- usuarios (crear/editar rol se hace vía panel admin + Supabase Auth Admin API,
-- nunca exponiendo el service_role key al cliente).
-- ---------------------------------------------------------------------------
create policy "perfiles_select_misma_tienda" on public.perfiles
  for select using (tienda_id = public.tienda_actual());

create policy "perfiles_update_propio_o_propietario" on public.perfiles
  for update using (
    id = auth.uid()
    or (tienda_id = public.tienda_actual() and public.es_propietario())
  );

-- ---------------------------------------------------------------------------
-- categorias / productos: lectura para cualquier rol de la tienda,
-- escritura solo propietario (el cajero vende, no edita catálogo).
-- ---------------------------------------------------------------------------
create policy "categorias_select" on public.categorias
  for select using (tienda_id = public.tienda_actual());

create policy "categorias_write_propietario" on public.categorias
  for all using (tienda_id = public.tienda_actual() and public.es_propietario())
  with check (tienda_id = public.tienda_actual() and public.es_propietario());

create policy "productos_select" on public.productos
  for select using (tienda_id = public.tienda_actual());

create policy "productos_write_propietario" on public.productos
  for all using (tienda_id = public.tienda_actual() and public.es_propietario())
  with check (tienda_id = public.tienda_actual() and public.es_propietario());

-- ---------------------------------------------------------------------------
-- movimientos_inventario: cualquier rol de la tienda puede ver; los ajustes
-- manuales (entrada/salida/ajuste) solo el propietario. Los de tipo 'venta'
-- los crea el trigger de venta (security definer), no directamente el cliente.
-- ---------------------------------------------------------------------------
create policy "movimientos_select" on public.movimientos_inventario
  for select using (tienda_id = public.tienda_actual());

create policy "movimientos_insert_propietario" on public.movimientos_inventario
  for insert with check (
    tienda_id = public.tienda_actual()
    and public.es_propietario()
    and tipo in ('entrada','salida','ajuste')
  );

-- ---------------------------------------------------------------------------
-- cajas: cada quien ve las cajas de su tienda; solo puede abrir/cerrar la suya
-- propia (o el propietario, para supervisión).
-- ---------------------------------------------------------------------------
create policy "cajas_select" on public.cajas
  for select using (tienda_id = public.tienda_actual());

create policy "cajas_insert_propia" on public.cajas
  for insert with check (tienda_id = public.tienda_actual() and usuario_id = auth.uid());

create policy "cajas_update_propia_o_propietario" on public.cajas
  for update using (
    tienda_id = public.tienda_actual()
    and (usuario_id = auth.uid() or public.es_propietario())
  );

-- ---------------------------------------------------------------------------
-- ventas / detalle_venta: cualquier rol de la tienda registra ventas y ve
-- las ventas de su tienda (no solo las propias, para que el dueño audite).
-- No se permite update/delete directo: una venta se anula, no se borra.
-- ---------------------------------------------------------------------------
create policy "ventas_select" on public.ventas
  for select using (tienda_id = public.tienda_actual());

create policy "ventas_insert" on public.ventas
  for insert with check (tienda_id = public.tienda_actual() and usuario_id = auth.uid());

create policy "ventas_anular_propietario" on public.ventas
  for update using (tienda_id = public.tienda_actual() and public.es_propietario())
  with check (tienda_id = public.tienda_actual());

create policy "detalle_venta_select" on public.detalle_venta
  for select using (
    exists (select 1 from public.ventas v where v.id = venta_id and v.tienda_id = public.tienda_actual())
  );

create policy "detalle_venta_insert" on public.detalle_venta
  for insert with check (
    exists (select 1 from public.ventas v where v.id = venta_id and v.tienda_id = public.tienda_actual() and v.usuario_id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- contadores_ticket: solo lo toca la función de trigger (security definer);
-- ningún cliente necesita leerlo ni escribirlo directamente.
-- ---------------------------------------------------------------------------
create policy "contadores_sin_acceso_directo" on public.contadores_ticket
  for all using (false) with check (false);
