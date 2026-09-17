import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/impresora_service.dart';
import '../services/ventas_service.dart';
import '../state/carrito_provider.dart';

const _igvPorcentaje = 18.0; // TODO: leerlo de la tabla `tiendas` cuando haya multi-tienda en la app.

class CarritoPanel extends StatefulWidget {
  final String cajaId;
  final VoidCallback onVentaCompletada;
  const CarritoPanel({super.key, required this.cajaId, required this.onVentaCompletada});

  @override
  State<CarritoPanel> createState() => _CarritoPanelState();
}

class _CarritoPanelState extends State<CarritoPanel> {
  final _ventasService = VentasService();
  final _impresoraService = ImpresoraService();
  final _authService = AuthService();

  String _metodoPago = 'efectivo';
  bool _procesando = false;

  Future<void> _cobrar() async {
    final carrito = context.read<CarritoProvider>();
    if (carrito.estaVacio) return;

    setState(() => _procesando = true);
    try {
      final venta = await _ventasService.registrarVenta(
        items: carrito.items,
        cajaId: widget.cajaId,
        metodoPago: _metodoPago,
        igvPorcentaje: _igvPorcentaje,
      );

      final perfil = await _authService.obtenerMiPerfil();

      // La venta ya quedó guardada aunque falle la impresión — no perdemos
      // el registro contable por un problema de Bluetooth.
      bool impreso = false;
      try {
        impreso = await _impresoraService.imprimirTicket(
          nombreTienda: 'Abarrotes',
          numeroTicket: venta.numeroTicket,
          items: carrito.items,
          subtotal: venta.subtotal,
          igv: venta.igv,
          total: venta.total,
          metodoPago: _metodoPago,
          cajero: perfil.nombreCompleto,
        );
      } catch (_) {
        impreso = false;
      }

      carrito.vaciar();
      widget.onVentaCompletada();

      if (!mounted) return;
      Navigator.of(context).maybePop(); // cierra el bottom sheet si estaba abierto
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            impreso
                ? 'Venta #${venta.numeroTicket} registrada e impresa ✅'
                : 'Venta #${venta.numeroTicket} registrada. No se pudo imprimir (revisa la impresora).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo completar la venta: $e')),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final igv = carrito.subtotal * (_igvPorcentaje / 100);
    final total = carrito.subtotal + igv;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Carrito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: carrito.estaVacio
                ? const Center(child: Text('Agrega productos tocándolos en la lista', textAlign: TextAlign.center))
                : ListView.builder(
                    itemCount: carrito.items.length,
                    itemBuilder: (context, i) {
                      final item = carrito.items[i];
                      return ListTile(
                        title: Text(item.producto.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('S/ ${item.producto.precioVenta.toStringAsFixed(2)} c/u'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => context.read<CarritoProvider>().quitarUno(item.producto),
                            ),
                            Text(item.cantidad.toStringAsFixed(0)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => context.read<CarritoProvider>().agregar(item.producto),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _metodoPago,
                  decoration: const InputDecoration(labelText: 'Método de pago'),
                  items: const [
                    DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                    DropdownMenuItem(value: 'yape', child: Text('Yape')),
                    DropdownMenuItem(value: 'plin', child: Text('Plin')),
                    DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                  ],
                  onChanged: (v) => setState(() => _metodoPago = v ?? 'efectivo'),
                ),
                const SizedBox(height: 12),
                _FilaResumen(label: 'Subtotal', valor: carrito.subtotal),
                _FilaResumen(label: 'IGV ($_igvPorcentaje%)', valor: igv),
                _FilaResumen(label: 'Total', valor: total, destacado: true),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (carrito.estaVacio || _procesando) ? null : _cobrar,
                    child: Text(_procesando ? 'Procesando…' : 'Cobrar e imprimir'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String label;
  final double valor;
  final bool destacado;
  const _FilaResumen({required this.label, required this.valor, this.destacado = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: destacado ? FontWeight.bold : FontWeight.normal,
      fontSize: destacado ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('S/ ${valor.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
