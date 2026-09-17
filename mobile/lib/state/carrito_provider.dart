import 'package:flutter/foundation.dart';
import '../models/item_carrito.dart';
import '../models/producto.dart';

class CarritoProvider extends ChangeNotifier {
  final List<ItemCarrito> _items = [];

  List<ItemCarrito> get items => List.unmodifiable(_items);

  double get subtotal => _items.fold(0, (acc, i) => acc + i.subtotal);

  bool get estaVacio => _items.isEmpty;

  void agregar(Producto producto) {
    final existente = _items.where((i) => i.producto.id == producto.id).firstOrNull;
    if (existente != null) {
      if (existente.cantidad + 1 > producto.stockActual) return; // no exceder stock visible
      existente.cantidad += 1;
    } else {
      if (producto.stockActual < 1) return;
      _items.add(ItemCarrito(producto: producto));
    }
    notifyListeners();
  }

  void quitarUno(Producto producto) {
    final existente = _items.where((i) => i.producto.id == producto.id).firstOrNull;
    if (existente == null) return;
    if (existente.cantidad <= 1) {
      _items.remove(existente);
    } else {
      existente.cantidad -= 1;
    }
    notifyListeners();
  }

  void eliminar(Producto producto) {
    _items.removeWhere((i) => i.producto.id == producto.id);
    notifyListeners();
  }

  void vaciar() {
    _items.clear();
    notifyListeners();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
