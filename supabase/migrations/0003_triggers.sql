-- ============================================================================
-- POS Abarrotes — 0003_triggers.sql
-- Reglas de negocio que deben cumplirse SIEMPRE, sin importar si vienen del
-- panel web, de la app Flutter o de un futuro cliente: numeración de ticket,
-- descuento de stock y bloqueo de venta sin stock suficiente.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Asigna numero_ticket correlativo por tienda antes de insertar una venta.
-- ---------------------------------------------------------------------------
create or replace function public.asignar_numero_ticket()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  siguiente integer;
begin
  insert into public.contadores_ticket (tienda_id, ultimo)
  values (new.tienda_id, 1)
  on conflict (tienda_id) do update set ultimo = contadores_ticket.ultimo + 1
  returning ultimo into siguiente;

  new.numero_ticket := siguiente;
  return new;
end;
$$;

drop trigger if exists trg_asignar_numero_ticket on public.ventas;
create trigger trg_asignar_numero_ticket
  before insert on public.ventas
  for each row execute function public.asignar_numero_ticket();

-- ---------------------------------------------------------------------------
-- Al insertar una línea de detalle_venta: valida stock, descuenta inventario
-- y registra el movimiento. Si no alcanza el stock, aborta toda la venta.
-- ---------------------------------------------------------------------------
create or replace function public.aplicar_detalle_venta()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  stock_disponible numeric(10,2);
  venta_tienda_id uuid;
  venta_usuario_id uuid;
begin
  select stock_actual into stock_disponible
    from public.productos where id = new.producto_id for update;

  if stock_disponible is null then
    raise exception 'Producto % no existe', new.producto_id;
  end if;

  if stock_disponible < new.cantidad then
    raise exception 'Stock insuficiente para el producto % (disponible: %, pedido: %)',
      new.producto_id, stock_disponible, new.cantidad;
  end if;

  update public.productos
     set stock_actual = stock_actual - new.cantidad,
         updated_at = now()
   where id = new.producto_id;

  select tienda_id, usuario_id into venta_tienda_id, venta_usuario_id
    from public.ventas where id = new.venta_id;

  insert into public.movimientos_inventario (tienda_id, producto_id, tipo, cantidad, motivo, usuario_id)
  values (venta_tienda_id, new.producto_id, 'venta', -new.cantidad, 'Venta #' || new.venta_id, venta_usuario_id);

  return new;
end;
$$;

drop trigger if exists trg_aplicar_detalle_venta on public.detalle_venta;
create trigger trg_aplicar_detalle_venta
  after insert on public.detalle_venta
  for each row execute function public.aplicar_detalle_venta();

-- ---------------------------------------------------------------------------
-- Si se anula una venta (estado -> 'anulada'), devuelve el stock.
-- ---------------------------------------------------------------------------
create or replace function public.revertir_venta_anulada()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.estado = 'anulada' and old.estado <> 'anulada' then
    update public.productos p
       set stock_actual = p.stock_actual + dv.cantidad,
           updated_at = now()
      from public.detalle_venta dv
     where dv.venta_id = new.id and p.id = dv.producto_id;

    insert into public.movimientos_inventario (tienda_id, producto_id, tipo, cantidad, motivo, usuario_id)
    select new.tienda_id, dv.producto_id, 'ajuste', dv.cantidad, 'Anulación venta #' || new.id, new.usuario_id
      from public.detalle_venta dv where dv.venta_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_revertir_venta_anulada on public.ventas;
create trigger trg_revertir_venta_anulada
  after update on public.ventas
  for each row execute function public.revertir_venta_anulada();

-- ---------------------------------------------------------------------------
-- updated_at automático en productos
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_productos_updated_at on public.productos;
create trigger trg_productos_updated_at
  before update on public.productos
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Crear automáticamente el perfil (rol 'propietario' por defecto) cuando se
-- registra un usuario nuevo vía Supabase Auth y ya se le asignó tienda_id
-- en los metadatos de la invitación. Ver docs/DESPLIEGUE.md para el flujo
-- de alta del primer usuario (propietario) de la tienda.
-- ---------------------------------------------------------------------------
create or replace function public.manejar_nuevo_usuario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.raw_user_meta_data ? 'tienda_id' then
    insert into public.perfiles (id, tienda_id, nombre_completo, rol)
    values (
      new.id,
      (new.raw_user_meta_data->>'tienda_id')::uuid,
      coalesce(new.raw_user_meta_data->>'nombre_completo', new.email),
      coalesce((new.raw_user_meta_data->>'rol')::public.rol_usuario, 'cajero')
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_nuevo_usuario on auth.users;
create trigger trg_nuevo_usuario
  after insert on auth.users
  for each row execute function public.manejar_nuevo_usuario();
