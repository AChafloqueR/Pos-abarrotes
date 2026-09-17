import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Session? get sesionActual => _client.auth.currentSession;
  User? get usuarioActual => _client.auth.currentUser;

  Future<void> iniciarSesion({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }

  /// Trae el perfil (rol, tienda) del usuario autenticado. RLS asegura que
  /// solo pueda leer su propio perfil y los de su misma tienda.
  Future<Perfil> obtenerMiPerfil() async {
    final uid = usuarioActual?.id;
    if (uid == null) {
      throw StateError('No hay sesión activa');
    }
    final data = await _client.from('perfiles').select().eq('id', uid).single();
    return Perfil.fromMap(data);
  }
}
