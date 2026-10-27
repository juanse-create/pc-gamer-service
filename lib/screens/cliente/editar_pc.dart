import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarPC extends StatefulWidget {
  final String equipoId;
  final Map<String, dynamic> datos;

  const EditarPC({super.key, required this.equipoId, required this.datos});

  @override
  State<EditarPC> createState() => _EditarPCState();
}

class _EditarPCState extends State<EditarPC> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nombre;
  late final TextEditingController procesador;
  late final TextEditingController grafica;
  late final TextEditingController ram;
  late final TextEditingController almacenamiento;
  late final TextEditingController descripcion;

  bool guardando = false;

  @override
  void initState() {
    super.initState();

    nombre = TextEditingController(
      text: widget.datos['nombre']?.toString() ?? '',
    );

    procesador = TextEditingController(
      text: widget.datos['procesador']?.toString() ?? '',
    );

    grafica = TextEditingController(
      text: widget.datos['grafica']?.toString() ?? '',
    );

    ram = TextEditingController(text: widget.datos['ram']?.toString() ?? '');

    almacenamiento = TextEditingController(
      text: widget.datos['almacenamiento']?.toString() ?? '',
    );

    descripcion = TextEditingController(
      text: widget.datos['descripcion']?.toString() ?? '',
    );
  }

  Future<void> guardarCambios() async {
    if (!_formKey.currentState!.validate() || guardando) {
      return;
    }

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión')));
      return;
    }

    setState(() => guardando = true);

    try {
      final equipoRef = FirebaseFirestore.instance
          .collection('equipos')
          .doc(widget.equipoId);

      final documento = await equipoRef.get();

      if (!documento.exists || documento.data()?['clienteId'] != usuario.uid) {
        throw Exception('No tienes permiso para editar este equipo');
      }

      await equipoRef.update({
        'nombre': nombre.text.trim(),
        'procesador': procesador.text.trim(),
        'grafica': grafica.text.trim(),
        'ram': ram.text.trim(),
        'almacenamiento': almacenamiento.text.trim(),
        'descripcion': descripcion.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipo actualizado correctamente')),
      );

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de Firebase: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  Widget campo(
    String etiqueta,
    TextEditingController controlador, {
    int maxLineas = 1,
    bool obligatorio = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controlador,
        maxLines: maxLineas,
        maxLength: maxLineas > 1 ? 1000 : 100,
        enabled: !guardando,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
        validator: (valor) {
          final texto = valor?.trim() ?? '';

          if (obligatorio && texto.isEmpty) {
            return 'Completa el campo $etiqueta';
          }

          if (texto.length > (maxLineas > 1 ? 1000 : 100)) {
            return 'El texto es demasiado largo';
          }

          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    nombre.dispose();
    procesador.dispose();
    grafica.dispose();
    ram.dispose();
    almacenamiento.dispose();
    descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar equipo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              campo('Nombre del equipo', nombre),
              campo('Procesador', procesador),
              campo('Tarjeta gráfica', grafica),
              campo('RAM', ram),
              campo('Almacenamiento', almacenamiento),
              campo(
                'Descripción',
                descripcion,
                maxLineas: 3,
                obligatorio: false,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: guardando ? null : guardarCambios,
                  icon: const Icon(Icons.save),
                  label: Text(guardando ? 'Guardando...' : 'Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
