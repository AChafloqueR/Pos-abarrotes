-- ============================================================================
-- POS Abarrotes — seed.sql
-- Datos de ejemplo para desarrollo/pruebas. NO ejecutar en producción.
-- Uso: supabase db reset (lo aplica automático) o psql -f seed/seed.sql
-- ============================================================================

insert into public.tiendas (id, nombre, ruc, direccion, moneda, igv_porcentaje)
values ('00000000-0000-0000-0000-000000000001', 'Botica/Abarrotes Chao', '10000000001', 'Chao, Virú, La Libertad', 'PEN', 18.00)
on conflict (id) do nothing;

insert into public.categorias (id, tienda_id, nombre) values
  ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 'Abarrotes'),
  ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000001', 'Bebidas'),
  ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000001', 'Limpieza'),
  ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000001', 'Snacks')
on conflict do nothing;

insert into public.productos (tienda_id, categoria_id, codigo_barras, nombre, precio_venta, costo, stock_actual, stock_minimo, unidad_medida) values
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000101', '7750182000019', 'Arroz Costeño 5kg', 24.90, 20.00, 40, 10, 'bolsa'),
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000101', '7750182000026', 'Aceite Primor 1L', 12.50, 10.20, 30, 8, 'botella'),
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000101', '7750182000033', 'Azúcar Rubia 1kg', 4.50, 3.60, 60, 15, 'bolsa'),
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000102', '7750182000040', 'Inca Kola 1.5L', 6.50, 5.00, 24, 6, 'botella'),
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000102', '7750182000057', 'Agua San Luis 625ml', 2.00, 1.30, 50, 12, 'botella'),
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103', '7750182000064', 'Detergente Ariel 850g', 15.90, 12.80, 20, 5, 'bolsa'),
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000104', '7750182000071', 'Galleta Soda Field', 1.50, 1.00, 80, 20, 'paquete')
on conflict do nothing;

-- Nota: los usuarios (propietario/cajero) NO se siembran aquí porque viven en
-- auth.users, que administra Supabase. Créalos desde el panel de Supabase
-- Authentication > Users, agregando en "User Metadata":
--   { "tienda_id": "00000000-0000-0000-0000-000000000001", "nombre_completo": "Anabel", "rol": "propietario" }
-- El trigger trg_nuevo_usuario crea el perfil automáticamente. Detalle en docs/DESPLIEGUE.md.
