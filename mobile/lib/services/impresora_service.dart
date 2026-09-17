import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../models/item_carrito.dart';

/// Encapsula la impresión ESC/POS por Bluetooth clásico, compatible con la
/// mayoría de ticketeras térmicas 58mm/80mm que se consiguen en Perú
/// (Xprinter, Ganzhi, Genérica "POS-58", etc.).
class ImpresoraService {
  Future<bool> tienePermisoBluetooth() async {
    return PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<List<BluetoothInfo>> dispositivosEmparejados() async {
    return PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> conectar(String macAddress) {
    return PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  Future<bool> desconectar() => PrintBluetoothThermal.disconnect;

  Future<bool> get estaConectada => PrintBluetoothThermal.connectionStatus;

  /// Genera el ticket en bytes ESC/POS e imprime. Formato pensado para
  /// papel de 58mm (32 columnas); para 80mm usa PaperSize.mm80.
  Future<bool> imprimirTicket({
    required String nombreTienda,
    required int numeroTicket,
    required List<ItemCarrito> items,
    required double subtotal,
    required double igv,
    required double total,
    required String metodoPago,
    required String cajero,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final List<int> bytes = [];

    bytes.addAll(generator.text(
      nombreTienda,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    ));
    bytes.addAll(generator.text(
      'Ticket #$numeroTicket',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.text(
      DateTime.now().toString().substring(0, 16),
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.hr());

    for (final item in items) {
      bytes.addAll(generator.text(item.producto.nombre, styles: const PosStyles(bold: true)));
      bytes.addAll(generator.row([
        PosColumn(text: '${item.cantidad} x S/ ${item.producto.precioVenta.toStringAsFixed(2)}', width: 8),
        PosColumn(
          text: 'S/ ${item.subtotal.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    bytes.addAll(generator.hr());
    bytes.addAll(generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(text: 'S/ ${subtotal.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(generator.row([
      PosColumn(text: 'IGV', width: 8),
      PosColumn(text: 'S/ ${igv.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]));
    bytes.addAll(generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
        text: 'S/ ${total.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]));
    bytes.addAll(generator.text('Pago: $metodoPago'));
    bytes.addAll(generator.text('Atendido por: $cajero', styles: const PosStyles(fontType: PosFontType.fontB)));
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text(
      '¡Gracias por su compra!',
      styles: const PosStyles(align: PosAlign.center),
    ));
    bytes.addAll(generator.cut());

    return PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
  }
}
