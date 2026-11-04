import 'package:flutter/material.dart';

/// Pantalla Vacía - Pantalla inicial de la aplicación CastaSoft
///
/// Esta pantalla sirve como punto de inicio de la aplicación.
/// Contiene un Scaffold simple con AppBar y un cuerpo centrado.
///
/// Propiedades:
/// - AppBar: Muestra el título "Dashboard"
/// - Body: Centro con texto grande que dice "CastaSoft Inicial"
class PantallaVacia extends StatelessWidget {
  /// Constructor de la pantalla vacía
  const PantallaVacia({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// AppBar de la pantalla principal
      /// Configuración simple con un título
      appBar: AppBar(title: const Text('Dashboard'), elevation: 0),

      /// Cuerpo principal de la pantalla
      /// Centrado con el widget Center para alinear el contenido
      body: const Center(
        child: Text(
          'CastaSoft Inicial',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
