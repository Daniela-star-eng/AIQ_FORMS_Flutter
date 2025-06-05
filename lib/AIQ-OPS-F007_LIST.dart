import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AIQ_OPS_F007_detail.dart';

class AIQOPSF007ListScreen extends StatelessWidget {
  const AIQOPSF007ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formularios Guardados F007')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('aiq_ops_f007')
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
                title: Text('Folio: ${data['folio'] ?? ''}'),
                subtitle: Text('Fecha: ${data['fecha'] ?? ''}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AIQOPSF007DetailScreen(
                        docId: docs[index].id,
                        data: data,
                      ),
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