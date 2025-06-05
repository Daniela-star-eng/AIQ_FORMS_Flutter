import 'package:flutter/material.dart';

class AIQOPSF007DetailScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const AIQOPSF007DetailScreen({super.key, required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final selecciones = (data['selecciones'] as Map?) ?? {};
    return Scaffold(
      appBar: AppBar(title: Text('Detalle F007 - Folio: ${data['folio'] ?? ''}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Fecha: ${data['fecha'] ?? ''}', style: const TextStyle(fontSize: 16)),
            Text('Hora: ${data['hora'] ?? ''}', style: const TextStyle(fontSize: 16)),
            Text('Número de Inspección: ${data['numero_inspeccion'] ?? ''}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Observaciones Generales:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(data['observaciones_generales'] ?? ''),
            const SizedBox(height: 16),
            Text('Enterado: ${data['enterado_nombre'] ?? ''}'),
            Text('Fecha Enterado: ${data['enterado_fecha'] ?? ''}'),
            const SizedBox(height: 16),
            const Text('Respuestas del Formulario:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...selecciones.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${e.key}: ${e.value}'),
            )),
          ],
        ),
      ),
    );
  }
}