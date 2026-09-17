class Producto {
  final String id;
  final String tiendaId;
  final String? categoriaId;
  final String? codigoBarras;
  final String nombre;
  final double precioVenta;
  final double stockActual;
  final double stockMinimo;
  final String unidadMedida;
  final bool activo;

  Producto({
    required this.id,
    required this.tiendaId,
    this.categoriaId,
    this.codigoBarras,
    required this.nombre,
    required this.precioVenta,
    required this.stockActual,
    required this.stockMinimo,
    required this.unidadMedida,
    required this.activo,
  });

  bool get stockBajo => stockActual <= stockMinimo;

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'] as String,
      tiendaId: map['tienda_id'] as String,
      categoriaId: map['categoria_id'] as String?,
      codigoBarras: map['codigo_barras'] as String?,
      nombre: map['nombre'] as String,
      precioVenta: (map['precio_venta'] as num).toDouble(),
      stockActual: (map['stock_actual'] as num).toDouble(),
      stockMinimo: (map['stock_minimo'] as num).toDouble(),
      unidadMedida: map['unidad_medida'] as String? ?? 'unidad',
      activo: map['activo'] as bool? ?? true,
    );
  }
}
