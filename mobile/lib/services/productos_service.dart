import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producto.dart';

class ProductosService {
  final SupabaseClient _client = Supabase.instance.client;

  /// RLS filtra automáticamente por la tienda del usuario autenticado —
  /// no hace falta (ni se debe) pasar tienda_id manualmente aquí.
  Future<List<Producto>> listarActivos() async {
    final data = await _client
        .from('productos')
        .select()
        .eq('activo', true)
        .order('nombre');
    return (data as List).map((m) => Producto.fromMap(m as Map<String, dynamic>)).toList();
  }

  Future<List<Producto>> buscar(String termino) async {
    if (termino.trim().isEmpty) return listarActivos();
    final data = await _client
        .from('productos')
        .select()
        .eq('activo', true)
        .or('nombre.ilike.%$termino%,codigo_barras.ilike.%$termino%')
        .order('nombre');
    return (data as List).map((m) => Producto.fromMap(m as Map<String, dynamic>)).toList();
  }
}
