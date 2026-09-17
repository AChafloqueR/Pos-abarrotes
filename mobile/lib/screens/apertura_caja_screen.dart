import 'package:flutter/material.dart';
import '../services/caja_service.dart';
import 'venta_screen.dart';

/// Pantalla obligatoria antes de vender: el cajero declara con cuánto
/// efectivo abre su turno. Esto permite cuadrar caja al cierre.
class AperturaCajaScreen extends StatefulWidget {
  const AperturaCajaScreen({super.key});

  @override
  State<AperturaCajaScreen> createState() => _AperturaCajaScreenState();
}

class _AperturaCajaScreenState extends State<AperturaCajaScreen> {
  final _cajaService = CajaService();
  final _montoCtrl = TextEditingController(text: '0.00');
  bool _verificando = true;
  bool _abriendo = false;

  @override
  void initState() {
    super.initState();
    _verificarCajaExistente();
  }

  Future<void> _verificarCajaExistente() async {
    final cajaId = await _cajaService.cajaAbiertaId();
    if (!mounted) return;
    if (cajaId != null) {
      _irAVenta(cajaId);
      return;
    }
    setState(() => _verificando = false);
  }

  void _irAVenta(String cajaId) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => VentaScreen(cajaId: cajaId)),
    );
  }

  Future<void> _abrirCaja() async {
    final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;
    setState(() => _abriendo = true);
    try {
      final cajaId = await _cajaService.abrirCaja(montoApertura: monto);
      if (!mounted) return;
      _irAVenta(cajaId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir caja: $e')),
      );
      setState(() => _abriendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Apertura de caja')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.point_of_sale, size: 48),
                const SizedBox(height: 12),
                const Text(
                  '¿Con cuánto efectivo abres tu turno?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: 'S/ ', labelText: 'Monto de apertura'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _abriendo ? null : _abrirCaja,
                    child: Text(_abriendo ? 'Abriendo…' : 'Abrir caja y empezar a vender'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
