import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/caja_service.dart';
import 'login_screen.dart';

class CierreCajaScreen extends StatefulWidget {
  final String cajaId;
  const CierreCajaScreen({super.key, required this.cajaId});

  @override
  State<CierreCajaScreen> createState() => _CierreCajaScreenState();
}

class _CierreCajaScreenState extends State<CierreCajaScreen> {
  final _cajaService = CajaService();
  final _authService = AuthService();
  final _montoCierreCtrl = TextEditingController();
  final _montoEsperadoCtrl = TextEditingController();
  bool _cerrando = false;

  Future<void> _cerrarCaja() async {
    final cierre = double.tryParse(_montoCierreCtrl.text.replaceAll(',', '.')) ?? 0;
    final esperado = double.tryParse(_montoEsperadoCtrl.text.replaceAll(',', '.')) ?? 0;

    setState(() => _cerrando = true);
    try {
      await _cajaService.cerrarCaja(cajaId: widget.cajaId, montoCierre: cierre, montoEsperado: esperado);
      await _authService.cerrarSesion();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cerrar caja: $e')),
      );
      setState(() => _cerrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cierre de caja')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cuenta el efectivo real en caja y regístralo para cuadrar el turno.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _montoEsperadoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: 'S/ ', labelText: 'Monto esperado (según sistema)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _montoCierreCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: 'S/ ', labelText: 'Monto contado (real)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cerrando ? null : _cerrarCaja,
                    child: Text(_cerrando ? 'Cerrando…' : 'Cerrar caja y salir'),
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
