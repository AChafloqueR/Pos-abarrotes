import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/producto.dart';
import '../services/productos_service.dart';
import '../state/carrito_provider.dart';
import '../widgets/carrito_panel.dart';
import '../widgets/producto_card.dart';
import 'cierre_caja_screen.dart';

class VentaScreen extends StatefulWidget {
  final String cajaId;
  const VentaScreen({super.key, required this.cajaId});

  @override
  State<VentaScreen> createState() => _VentaScreenState();
}

class _VentaScreenState extends State<VentaScreen> {
  final _productosService = ProductosService();
  final _busquedaCtrl = TextEditingController();

  List<Producto> _productos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() => _cargando = true);
    final productos = await _productosService.listarActivos();
    if (!mounted) return;
    setState(() {
      _productos = productos;
      _cargando = false;
    });
  }

  Future<void> _buscar(String termino) async {
    final resultado = await _productosService.buscar(termino);
    if (!mounted) return;
    setState(() => _productos = resultado);
  }

  @override
  Widget build(BuildContext context) {
    final anchoAngosto = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Punto de venta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_clock),
            tooltip: 'Cerrar caja',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CierreCajaScreen(cajaId: widget.cajaId)),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _busquedaCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o código de barras…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busquedaCtrl.clear();
                          _cargarProductos();
                        },
                      ),
                    ),
                    onSubmitted: _buscar,
                  ),
                ),
                Expanded(
                  child: _cargando
                      ? const Center(child: CircularProgressIndicator())
                      : _productos.isEmpty
                          ? const Center(child: Text('No se encontraron productos'))
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _productos.length,
                              itemBuilder: (context, i) {
                                final producto = _productos[i];
                                return ProductoCard(
                                  producto: producto,
                                  onTap: () => context.read<CarritoProvider>().agregar(producto),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          if (!anchoAngosto)
            SizedBox(
              width: 340,
              child: CarritoPanel(cajaId: widget.cajaId, onVentaCompletada: _cargarProductos),
            ),
        ],
      ),
      bottomSheet: anchoAngosto
          ? _ResumenCarritoBottomBar(cajaId: widget.cajaId, onVentaCompletada: _cargarProductos)
          : null,
    );
  }
}

class _ResumenCarritoBottomBar extends StatelessWidget {
  final String cajaId;
  final VoidCallback onVentaCompletada;
  const _ResumenCarritoBottomBar({required this.cajaId, required this.onVentaCompletada});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    if (carrito.estaVacio) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => FractionallySizedBox(
                heightFactor: 0.85,
                child: CarritoPanel(cajaId: cajaId, onVentaCompletada: onVentaCompletada),
              ),
            ),
            child: Text('Ver carrito (${carrito.items.length}) · S/ ${carrito.subtotal.toStringAsFixed(2)}'),
          ),
        ),
      ),
    );
  }
}
