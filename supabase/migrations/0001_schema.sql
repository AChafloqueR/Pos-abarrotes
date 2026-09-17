-- ============================================================================
-- POS Abarrotes — 0001_schema.sql
-- Esquema base: tiendas, perfiles/roles, catálogo, inventario, caja y ventas.
-- Diseñado multi-tienda (tienda_id) por si en el futuro abres una segunda
-- sucursal, aunque hoy uses una sola.
-- ============================================================================

create extension if not exists "pgcrypto"; -- gen_random_uuid()

-- ---------------------------------------------------------------------------
-- Tiendas
-- ---------------------------------------------------------------------------
create table if not exists public.tiendas (
  id            uuid primary key default gen_random_uuid(),
  nombre        text not null,
  ruc           text,
  direccion     text,
  moneda        text not null default 'PEN',
  igv_porcentaje numeric(5,2) not null default 18.00,
  created_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Perfiles (1:1 con auth.users). El rol controla lo que cada quien puede hacer.
-- ---------------------------------------------------------------------------
create type public.rol_usuario as enum ('propietario', 'cajero');

create table if not exists public.perfiles (
  id                uuid primary key references auth.users(id) on delete cascade,
  tienda_id         uuid not null references public.tiendas(id) on delete cascade,
  nombre_completo   text not null,
  rol               public.rol_usuario not null default 'cajero',
  activo            boolean not null default true,
  created_at        timestamptz not null default now()
);

create index if not exists idx_perfiles_tienda on public.perfiles(tienda_id);

-- ---------------------------------------------------------------------------
-- Catálogo
-- ---------------------------------------------------------------------------
create table if not exists public.categorias (
  id          uuid primary key default gen_random_uuid(),
  tienda_id   uuid not null references public.tiendas(id) on delete cascade,
  nombre      text not null,
  created_at  timestamptz not null default now(),
  unique (tienda_id, nombre)
);

create table if not exists public.productos (
  id              uuid primary key default gen_random_uuid(),
  tienda_id       uuid not null references public.tiendas(id) on delete cascade,
  categoria_id    uuid references public.categorias(id) on delete set null,
  codigo_barras   text,
  nombre          text not null,
  descripcion     text,
  precio_venta    numeric(10,2) not null check (precio_venta >= 0),
  costo           numeric(10,2) not null default 0 check (costo >= 0),
  stock_actual    numeric(10,2) not null default 0 check (stock_actual >= 0),
  stock_minimo    numeric(10,2) not null default 0,
  unidad_medida   text not null default 'unidad', -- unidad, kg, litro, paquete...
  activo          boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (tienda_id, codigo_barras)
);

create index if not exists idx_productos_tienda on public.productos(tienda_id);
create index if not exists idx_productos_nombre on public.productos using gin (to_tsvector('spanish', nombre));

create table if not exists public.movimientos_inventario (
  id            uuid primary key default gen_random_uuid(),
  tienda_id     uuid not null references public.tiendas(id) on delete cascade,
  producto_id   uuid not null references public.productos(id) on delete cascade,
  tipo          text not null check (tipo in ('entrada','salida','ajuste','venta')),
  cantidad      numeric(10,2) not null,
  motivo        text,
  usuario_id    uuid references public.perfiles(id),
  created_at    timestamptz not null default now()
);

create index if not exists idx_movimientos_producto on public.movimientos_inventario(producto_id);

-- ---------------------------------------------------------------------------
-- Caja (apertura/cierre de turno del cajero)
-- ---------------------------------------------------------------------------
create table if not exists public.cajas (
  id              uuid primary key default gen_random_uuid(),
  tienda_id       uuid not null references public.tiendas(id) on delete cascade,
  usuario_id      uuid not null references public.perfiles(id),
  monto_apertura  numeric(10,2) not null default 0,
  monto_cierre    numeric(10,2),
  monto_esperado  numeric(10,2),
  diferencia      numeric(10,2),
  estado          text not null default 'abierta' check (estado in ('abierta','cerrada')),
  abierta_at      timestamptz not null default now(),
  cerrada_at      timestamptz
);

create index if not exists idx_cajas_tienda on public.cajas(tienda_id, estado);

-- ---------------------------------------------------------------------------
-- Ventas
-- ---------------------------------------------------------------------------
create table if not exists public.ventas (
  id              uuid primary key default gen_random_uuid(),
  tienda_id       uuid not null references public.tiendas(id) on delete cascade,
  caja_id         uuid not null references public.cajas(id),
  usuario_id      uuid not null references public.perfiles(id),
  numero_ticket   integer not null,
  subtotal        numeric(10,2) not null check (subtotal >= 0),
  igv             numeric(10,2) not null default 0,
  total           numeric(10,2) not null check (total >= 0),
  metodo_pago     text not null check (metodo_pago in ('efectivo','yape','plin','tarjeta')),
  estado          text not null default 'completada' check (estado in ('completada','anulada')),
  created_at      timestamptz not null default now(),
  unique (tienda_id, numero_ticket)
);

create index if not exists idx_ventas_tienda_fecha on public.ventas(tienda_id, created_at desc);

create table if not exists public.detalle_venta (
  id              uuid primary key default gen_random_uuid(),
  venta_id        uuid not null references public.ventas(id) on delete cascade,
  producto_id     uuid not null references public.productos(id),
  cantidad        numeric(10,2) not null check (cantidad > 0),
  precio_unitario numeric(10,2) not null check (precio_unitario >= 0),
  subtotal        numeric(10,2) not null check (subtotal >= 0)
);

create index if not exists idx_detalle_venta_venta on public.detalle_venta(venta_id);

-- Secuencia de numero_ticket por tienda (se usa desde la función de trigger)
create table if not exists public.contadores_ticket (
  tienda_id   uuid primary key references public.tiendas(id) on delete cascade,
  ultimo      integer not null default 0
);
