import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'derrames_detail.dart'; // Agrega esta línea

class DerramesListScreen extends StatelessWidget {
  const DerramesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formularios de Derrames')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('derrames')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Folio: ${data['folio']} - ${data['fecha']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifica: ${data['nombreNotifica']}'),
                    Text('Causa de Derrame: ${data['causaDerrame'] ?? ''}'),
                    Text('Personal y Vehículos: ${data['personalVehiculos'] ?? ''}'),
                    Text('Observaciones: ${data['observaciones'] ?? ''}'),
                  ],
                ),
                trailing: Text('Criticidad: ${data['criticidad']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DerrameDetailScreen(data: data),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}