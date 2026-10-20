import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin/administrar_ordenes.dart';
import 'screens/admin/estadisticas.dart';
import 'screens/admin/gestionar_tecnicos.dart';
import 'screens/admin/gestionar_usuarios.dart';
import 'screens/auth/login_screen.dart' as auth;
import 'screens/cliente/mis_equipos.dart';
import 'screens/cliente/mis_ordenes.dart';
import 'screens/cliente/registrar_pc.dart';
import 'screens/cliente/solicitar_mantenimiento.dart';
import 'screens/tecnico/ordenes_tecnico.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PCGamerApp());
}

class PCGamerApp extends StatelessWidget {
  const PCGamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PC Gamer Service',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const auth.LoginScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String rol;

  const HomeScreen({super.key, required this.rol});

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService().cerrarSesion();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const auth.LoginScreen()),
      (route) => false,
    );
  }

  void _abrirPantalla(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  Widget _opcion(
    BuildContext context,
    String titulo,
    IconData icono,
    Widget pantalla,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icono, color: Colors.blueAccent),
        title: Text(titulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _abrirPantalla(context, pantalla),
      ),
    );
  }

  List<Widget> _opcionesPorRol(BuildContext context) {
    switch (rol) {
      case 'Cliente':
        return [
          _opcion(context, 'Mis equipos', Icons.devices, const MisEquipos()),
          _opcion(context, 'Registrar PC', Icons.computer, const RegistrarPC()),
          _opcion(
            context,
            'Solicitar mantenimiento',
            Icons.build_circle,
            const SolicitarMantenimiento(),
          ),
          _opcion(context, 'Mis órdenes', Icons.list_alt, const MisOrdenes()),
        ];

      case 'Técnico':
        return [
          _opcion(
            context,
            'Órdenes asignadas',
            Icons.assignment,
            const OrdenesTecnico(modo: 'consultar'),
          ),
          _opcion(
            context,
            'Registrar diagnóstico',
            Icons.build,
            const OrdenesTecnico(modo: 'diagnostico'),
          ),
          _opcion(
            context,
            'Actualizar estado',
            Icons.update,
            const OrdenesTecnico(modo: 'estado'),
          ),
        ];

      case 'Administrador':
        return [
          _opcion(
            context,
            'Gestionar usuarios',
            Icons.people,
            const GestionarUsuarios(),
          ),
          _opcion(
            context,
            'Gestionar técnicos',
            Icons.engineering,
            const GestionarTecnicos(),
          ),
          _opcion(
            context,
            'Todas las órdenes',
            Icons.assignment,
            const AdministrarOrdenes(),
          ),
          _opcion(
            context,
            'Asignar técnico',
            Icons.person_add,
            const AdministrarOrdenes(),
          ),
          _opcion(
            context,
            'Estadísticas',
            Icons.bar_chart,
            const Estadisticas(),
          ),
        ];

      default:
        return [const ListTile(title: Text('Rol no reconocido'))];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de $rol'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Bienvenido, $rol',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          ..._opcionesPorRol(context),
        ],
      ),
    );
  }
}
