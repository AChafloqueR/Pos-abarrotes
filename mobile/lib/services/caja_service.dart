import 'package:supabase_flutter/supabase_flutter.dart';

class CajaService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Devuelve el id de la caja abierta del usuario actual, o null si no
  /// tiene ninguna abierta (debe abrir una antes de vender).
  Future<String?> cajaAbiertaId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final data = await _client
        .from('cajas')
        .select('id')
        .eq('usuario_id', uid)
        .eq('estado', 'abierta')
        .maybeSingle();
    return data?['id'] as String?;
  }

  Future<String> abrirCaja({required double montoApertura}) async {
    final uid = _client.auth.currentUser?.id;
    final perfil = await _client.from('perfiles').select('tienda_id').eq('id', uid as Object).single();

    final data = await _client
        .from('cajas')
        .insert({
          'tienda_id': perfil['tienda_id'],
          'usuario_id': uid,
          'monto_apertura': montoApertura,
        })
        .select('id')
        .single();

    return data['id'] as String;
  }

  Future<void> cerrarCaja({
    required String cajaId,
    required double montoCierre,
    required double montoEsperado,
  }) async {
    await _client.from('cajas').update({
      'monto_cierre': montoCierre,
      'monto_esperado': montoEsperado,
      'diferencia': montoCierre - montoEsperado,
      'estado': 'cerrada',
      'cerrada_at': DateTime.now().toIso8601String(),
    }).eq('id', cajaId);
  }
}
