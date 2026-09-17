enum RolUsuario { propietario, cajero }

RolUsuario rolDesdeTexto(String texto) {
  return texto == 'propietario' ? RolUsuario.propietario : RolUsuario.cajero;
}

class Perfil {
  final String id;
  final String tiendaId;
  final String nombreCompleto;
  final RolUsuario rol;

  Perfil({
    required this.id,
    required this.tiendaId,
    required this.nombreCompleto,
    required this.rol,
  });

  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'] as String,
      tiendaId: map['tienda_id'] as String,
      nombreCompleto: map['nombre_completo'] as String,
      rol: rolDesdeTexto(map['rol'] as String),
    );
  }
}
