# Arquitectura

## Vista general

```
┌─────────────────┐        ┌──────────────────┐
│  App Flutter     │        │  Panel Next.js     │
│  (cajero, en la  │        │  (dueña, desde     │
│  tienda)         │        │  cualquier PC)      │
└────────┬─────────┘        └─────────┬──────────┘
         │  supabase_flutter          │  @supabase/ssr
         │  (REST + Realtime)         │  (REST)
         └───────────────┬────────────┘
                          │
                 ┌────────▼─────────┐
                 │     Supabase       │
                 │  Postgres + Auth   │
                 │  + RLS + Triggers  │
                 └────────────────────┘
```

Ambos clientes (app y panel) hablan directo con Supabase — no hay un backend intermedio propio que mantener. La lógica de negocio que *debe* cumplirse siempre (numerar tickets, descontar stock, no vender sin stock) vive en triggers de Postgres, no en el cliente, así que es imposible saltársela desde ningún cliente presente o futuro.

## Flujo de una venta

1. El cajero abre caja (`cajas`, estado `abierta`) con un monto inicial.
2. Busca/toca productos → se arma un carrito en memoria en la app (`CarritoProvider`).
3. Al cobrar: se inserta una fila en `ventas` → el trigger `asignar_numero_ticket` le pone el correlativo.
4. Por cada producto del carrito se inserta una fila en `detalle_venta` → el trigger `aplicar_detalle_venta`:
   - valida que haya stock suficiente (si no, aborta con un mensaje claro),
   - descuenta `productos.stock_actual`,
   - registra el movimiento en `movimientos_inventario`.
5. Se genera el ticket ESC/POS y se imprime por Bluetooth. Si la impresora falla, la venta *ya quedó guardada* — no se pierde el registro contable.
6. Al final del turno, el cajero cierra caja declarando el efectivo contado; queda guardada la diferencia para cuadre.

## Por qué este stack

- **Supabase**: te da base de datos + autenticación + seguridad (RLS) + backups gestionados sin tener que programar ni mantener un servidor backend propio. Tiene plan gratuito suficiente para una tienda pequeña.
- **Next.js en Vercel**: despliegue gratuito, automático en cada `git push`, ideal para el panel que la dueña revisa desde una computadora.
- **Flutter**: un solo código para Android (y iOS si algún día lo necesitas), con buen soporte de librerías para impresoras térmicas Bluetooth, que es el hardware más común y barato para ticketeras en Perú.

## Extensiones futuras (ver docs/ROADMAP.md)

- Boleta/factura electrónica SUNAT (requiere un PSE/OSE — se integra como un servicio aparte, no cambia este esquema base).
- Multi-tienda real (el esquema ya soporta varias `tiendas`, falta el selector en la UI).
- Reportes con gráficos (agregar `recharts` en el panel — ya está instalado en `package.json`, listo para usarse).
