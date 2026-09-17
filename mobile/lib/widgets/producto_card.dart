import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/producto.dart';

class ProductoCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;

  const ProductoCard({super.key, required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sinStock = producto.stockActual <= 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: sinStock ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                producto.nombre,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'S/ ${producto.precioVenta.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brand),
              ),
              const SizedBox(height: 4),
              Text(
                sinStock ? 'Sin stock' : '${producto.stockActual.toStringAsFixed(0)} ${producto.unidadMedida}',
                style: TextStyle(
                  fontSize: 12,
                  color: sinStock
                      ? AppColors.danger
                      : (producto.stockBajo ? AppColors.accent : Colors.grey),
                  fontWeight: producto.stockBajo ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
