import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Estadisticas extends StatelessWidget {
  const Estadisticas({super.key});

  // ==========================================
  // TARJETA DE ESTADÍSTICA
  // ==========================================

  Widget tarjeta(String titulo, int cantidad, IconData icono, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icono, color: color, size: 34),
            const SizedBox(width: 18),
            Expanded(child: Text(titulo, style: const TextStyle(fontSize: 16))),
            Text(
              '$cantidad',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PANTALLA DE ESTADÍSTICAS
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('equipos').snapshots(),
        builder: (context, equiposSnapshot) {
          if (equiposSnapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar equipos: ${equiposSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!equiposSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalEquipos = equiposSnapshot.data!.docs.length;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection('ordenes').snapshots(),
            builder: (context, ordenesSnapshot) {
              if (ordenesSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error al cargar órdenes: ${ordenesSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (!ordenesSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final ordenes = ordenesSnapshot.data!.docs;

              final totalOrdenes = ordenes.length;

              int pendientes = 0;
              int asignadas = 0;
              int enDiagnostico = 0;
              int enMantenimiento = 0;
              int terminadas = 0;
              int entregadas = 0;

              // Contar las órdenes por estado.
              for (final documento in ordenes) {
                final datos = documento.data();

                final estado = datos['estado']?.toString() ?? '';

                switch (estado) {
                  case 'Pendiente':
                    pendientes++;
                    break;

                  case 'Asignado':
                    asignadas++;
                    break;

                  case 'En diagnóstico':
                    enDiagnostico++;
                    break;

                  case 'En mantenimiento':
                    enMantenimiento++;
                    break;

                  case 'Terminado':
                    terminadas++;
                    break;

                  case 'Entregado':
                    entregadas++;
                    break;
                }
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Resumen general',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Información actualizada desde Firebase',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  // EQUIPOS
                  tarjeta(
                    'Equipos registrados',
                    totalEquipos,
                    Icons.computer,
                    Colors.blue,
                  ),

                  // TOTAL DE ÓRDENES
                  tarjeta(
                    'Total de órdenes',
                    totalOrdenes,
                    Icons.assignment,
                    Colors.cyan,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Estados de las órdenes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  // PENDIENTES
                  tarjeta(
                    'Órdenes pendientes',
                    pendientes,
                    Icons.pending_actions,
                    Colors.orange,
                  ),

                  // ASIGNADAS
                  tarjeta(
                    'Órdenes asignadas',
                    asignadas,
                    Icons.engineering,
                    Colors.purple,
                  ),

                  // EN DIAGNÓSTICO
                  tarjeta(
                    'En diagnóstico',
                    enDiagnostico,
                    Icons.search,
                    Colors.indigo,
                  ),

                  // EN MANTENIMIENTO
                  tarjeta(
                    'En mantenimiento',
                    enMantenimiento,
                    Icons.build,
                    Colors.deepOrange,
                  ),

                  // TERMINADAS
                  tarjeta(
                    'Órdenes terminadas',
                    terminadas,
                    Icons.check_circle,
                    Colors.green,
                  ),

                  // ENTREGADAS
                  tarjeta(
                    'Órdenes entregadas',
                    entregadas,
                    Icons.inventory_2,
                    Colors.teal,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
