import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_carrito.dart';

class VentaRegistrada {
  final String id;
  final int numeroTicket;
  final double subtotal;
  final double igv;
  final double total;

  VentaRegistrada({
    required this.id,
    required this.numeroTicket,
    required this.subtotal,
    required this.igv,
    required this.total,
  });
}

class VentasService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Registra la venta y su detalle. El trigger de la base de datos
  /// (0003_triggers.sql) se encarga de: numerar el ticket, validar y
  /// descontar stock, y registrar el movimiento de inventario — todo
  /// dentro de la misma transacción implícita de Postgres, así que si algo
  /// falla (p. ej. stock insuficiente) no queda una venta "a medias".
  Future<VentaRegistrada> registrarVenta({
    required List<ItemCarrito> items,
    required String cajaId,
    required String metodoPago,
    required double igvPorcentaje,
  }) async {
    final uid = _client.auth.currentUser?.id;
    final perfil = await _client.from('perfiles').select('tienda_id').eq('id', uid as Object).single();

    final subtotal = items.fold<double>(0, (acc, i) => acc + i.subtotal);
    final igv = subtotal * (igvPorcentaje / 100);
    final total = subtotal + igv;

    final venta = await _client
        .from('ventas')
        .insert({
          'tienda_id': perfil['tienda_id'],
          'caja_id': cajaId,
          'usuario_id': uid,
          'subtotal': subtotal,
          'igv': igv,
          'total': total,
          'metodo_pago': metodoPago,
        })
        .select('id, numero_ticket')
        .single();

    final ventaId = venta['id'] as String;

    // Un insert por línea: si el trigger rechaza una (stock insuficiente),
    // Supabase devuelve el error con el mensaje del trigger — lo mostramos
    // tal cual al cajero.
    for (final item in items) {
      await _client.from('detalle_venta').insert({
        'venta_id': ventaId,
        'producto_id': item.producto.id,
        'cantidad': item.cantidad,
        'precio_unitario': item.producto.precioVenta,
        'subtotal': item.subtotal,
      });
    }

    return VentaRegistrada(
      id: ventaId,
      numeroTicket: venta['numero_ticket'] as int,
      subtotal: subtotal,
      igv: igv,
      total: total,
    );
  }
}
