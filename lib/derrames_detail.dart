import 'package:flutter/material.dart';

class DerrameDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DerrameDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del Formulario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Fecha/Hora de notificación: ${data['fechaHoraNotificacion'] ?? ""}'),
            Text('Hora de llegada: ${data['horaLlegada'] ?? ""}'),
            Text('Nombre de quien notifica: ${data['nombreNotifica'] ?? ""}'),
            Text('Ubicación de derrame: ${data['ubicacion'] ?? ""}'),
            Text('Criticidad: ${data['criticidad'] ?? ""}'),
            Text('Producto derramado: ${data['producto'] ?? ""}'),
            Text('Originado por: ${data['originadoPor'] ?? ""}'),
            Text('No. vuelo/matrícula/No.Económico/Compañía: ${data['vueloMatricula'] ?? ""}'),
            Text('Espuma contra incendios: ${data['espuma'] ?? ""}'),
            Text('Material absorbente: ${data['materialAbsorbente'] ?? ""}'),
            Text('Líquido desengrasante: ${data['liquidoDesengrasante'] ?? ""}'),
            Text('Agua: ${data['agua'] ?? ""}'),
            Text('Área afectada: ${data['areaAfectada'] ?? ""}'),
            Text('Tiempo empleado: ${data['tiempoMinutos'] ?? ""}'),
            Text('Causa del derrame: ${data['causaDerrame'] ?? ""}'),
            Text('Personal y vehículos que atienden: ${data['personalVehiculos'] ?? ""}'),
            Text('Observaciones / comentarios: ${data['observaciones'] ?? ""}'),
          ],
        ),
      ),
    );
  }
}