// Tipos que reflejan el esquema de supabase/migrations/0001_schema.sql.
// Si cambias el esquema SQL, actualiza este archivo (o genera tipos con
// `supabase gen types typescript` — ver docs/DESPLIEGUE.md).

export type RolUsuario = "propietario" | "cajero";
export type MetodoPago = "efectivo" | "yape" | "plin" | "tarjeta";
export type EstadoVenta = "completada" | "anulada";

export interface Perfil {
  id: string;
  tienda_id: string;
  nombre_completo: string;
  rol: RolUsuario;
  activo: boolean;
  created_at: string;
}

export interface Categoria {
  id: string;
  tienda_id: string;
  nombre: string;
  created_at: string;
}

export interface Producto {
  id: string;
  tienda_id: string;
  categoria_id: string | null;
  codigo_barras: string | null;
  nombre: string;
  descripcion: string | null;
  precio_venta: number;
  costo: number;
  stock_actual: number;
  stock_minimo: number;
  unidad_medida: string;
  activo: boolean;
  created_at: string;
  updated_at: string;
}

export interface Venta {
  id: string;
  tienda_id: string;
  caja_id: string;
  usuario_id: string;
  numero_ticket: number;
  subtotal: number;
  igv: number;
  total: number;
  metodo_pago: MetodoPago;
  estado: EstadoVenta;
  created_at: string;
}

export interface DetalleVenta {
  id: string;
  venta_id: string;
  producto_id: string;
  cantidad: number;
  precio_unitario: number;
  subtotal: number;
}

export interface Caja {
  id: string;
  tienda_id: string;
  usuario_id: string;
  monto_apertura: number;
  monto_cierre: number | null;
  monto_esperado: number | null;
  diferencia: number | null;
  estado: "abierta" | "cerrada";
  abierta_at: string;
  cerrada_at: string | null;
}
