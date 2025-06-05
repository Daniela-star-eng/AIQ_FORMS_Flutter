import 'package:flutter/material.dart';

class AIQOPSF008DetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const AIQOPSF008DetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final selecciones = data['selecciones'] as Map<String, dynamic>? ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle AIQ-OPS-F008')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Fecha: ${data['fecha'] ?? ""}'),
          Text('Hora: ${data['hora'] ?? ""}'),
          Text('Número de Inspección: ${data['numero_inspeccion'] ?? ""}'),
          const SizedBox(height: 12),
          const Text('Observaciones Generales:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(data['observaciones_generales'] ?? ""),
          const SizedBox(height: 12),
          const Text('Selecciones:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...selecciones.entries.map((e) => Text('${e.key}: ${e.value}')),
        ],
      ),
    );
  }
}