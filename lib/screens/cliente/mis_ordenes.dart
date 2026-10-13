import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MisOrdenes extends StatelessWidget {
  const MisOrdenes({super.key});

  Color colorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'Asignado':
        return Colors.indigo;
      case 'En diagnóstico':
        return Colors.blue;
      case 'En mantenimiento':
        return Colors.purple;
      case 'Terminado':
        return Colors.green;
      case 'Entregado':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String formatearFecha(dynamic fecha) {
    if (fecha is! Timestamp) {
      return 'Fecha pendiente';
    }

    final fechaLocal = fecha.toDate().toLocal();

    String dosDigitos(int numero) => numero.toString().padLeft(2, '0');

    return '${dosDigitos(fechaLocal.day)}/'
        '${dosDigitos(fechaLocal.month)}/'
        '${fechaLocal.year} '
        '${dosDigitos(fechaLocal.hour)}:'
        '${dosDigitos(fechaLocal.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis órdenes')),
        body: const Center(
          child: Text('Debes iniciar sesión para consultar tus órdenes'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis órdenes')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ordenes')
            .where('clienteId', isEqualTo: usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error al cargar órdenes: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ordenes = snapshot.data!.docs.toList();

          // Ordenar por fecha sin necesitar un índice
          // compuesto de Firestore.
          ordenes.sort((a, b) {
            final fechaA = a.data()['fechaCreacion'];
            final fechaB = b.data()['fechaCreacion'];

            if (fechaA is! Timestamp && fechaB is! Timestamp) {
              return 0;
            }
            if (fechaA is! Timestamp) return 1;
            if (fechaB is! Timestamp) return -1;

            return fechaB.compareTo(fechaA);
          });

          if (ordenes.isEmpty) {
            return const Center(child: Text('Todavía no tienes solicitudes'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordenes.length,
            itemBuilder: (context, index) {
              final documento = ordenes[index];
              final orden = documento.data();

              final estado = orden['estado']?.toString() ?? 'Pendiente';

              final diagnostico = orden['diagnostico']?.toString() ?? '';

              final tecnicoNombre = orden['tecnicoNombre']?.toString() ?? '';

              final tecnico = tecnicoNombre.isNotEmpty
                  ? tecnicoNombre
                  : (orden['tecnicoId'] == null
                        ? 'Sin asignar'
                        : 'Técnico asignado');

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${documento.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text('PC: ${orden['nombreEquipo'] ?? 'Sin nombre'}'),

                      Text('Servicio: ${orden['tipoServicio'] ?? ''}'),

                      const SizedBox(height: 10),

                      Text('Problema: ${orden['descripcion'] ?? ''}'),

                      const SizedBox(height: 10),

                      Text('Fecha: ${formatearFecha(orden['fechaCreacion'])}'),

                      const SizedBox(height: 14),

                      Chip(
                        label: Text(estado),
                        backgroundColor: colorEstado(
                          estado,
                        ).withValues(alpha: 0.2),
                        side: BorderSide(color: colorEstado(estado)),
                      ),

                      const SizedBox(height: 10),

                      Text('Técnico: $tecnico'),

                      if (diagnostico.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Diagnóstico: $diagnostico'),
                      ],
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
