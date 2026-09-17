import 'producto.dart';

class ItemCarrito {
  final Producto producto;
  double cantidad;

  ItemCarrito({required this.producto, this.cantidad = 1});

  double get subtotal => producto.precioVenta * cantidad;
}
