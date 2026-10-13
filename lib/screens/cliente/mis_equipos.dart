import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'registrar_pc.dart';

class MisEquipos extends StatelessWidget {
  const MisEquipos({super.key});

  Future<void> eliminar(BuildContext context, String equipoId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar equipo'),
        content: const Text(
          '¿Seguro que deseas eliminar esta PC? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('equipos')
          .doc(equipoId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipo eliminado correctamente')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return const Scaffold(
        body: Center(
          child: Text('Debes iniciar sesión para consultar tus equipos'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis equipos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegistrarPC()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('equipos')
            .where('clienteId', isEqualTo: usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar equipos: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final equipos = snapshot.data?.docs ?? [];

          if (equipos.isEmpty) {
            return const Center(
              child: Text('Todavía no tienes equipos registrados'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: equipos.length,
            itemBuilder: (context, index) {
              final documento = equipos[index];
              final pc = documento.data();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.computer,
                          color: Colors.blueAccent,
                          size: 38,
                        ),
                        title: Text(
                          pc['nombre']?.toString() ?? 'Sin nombre',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${documento.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Divider(),
                      Text('CPU: ${pc['procesador'] ?? ''}'),
                      Text('GPU: ${pc['grafica'] ?? ''}'),
                      Text('RAM: ${pc['ram'] ?? ''}'),
                      Text('Almacenamiento: ${pc['almacenamiento'] ?? ''}'),
                      if ((pc['descripcion'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Descripción: ${pc['descripcion']}'),
                      ],
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => eliminar(context, documento.id),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          label: const Text('Eliminar'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
