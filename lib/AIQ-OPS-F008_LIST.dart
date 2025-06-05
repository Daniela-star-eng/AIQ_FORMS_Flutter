import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AIQ-OPS-F008_detail.dart';

class AIQOPSF008ListScreen extends StatelessWidget {
  const AIQOPSF008ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formularios AIQ-OPS-F008')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('aiq_ops_f008')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No hay formularios guardados.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Fecha: ${data['fecha'] ?? ''}'),
                subtitle: Text('Inspección: ${data['numero_inspeccion'] ?? ''}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AIQOPSF008DetailScreen(data: data),
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