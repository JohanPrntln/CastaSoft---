import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Componente LogoMarca - Encabezado de la aplicación
///
/// Widget simple que muestra el logo/marca de CastaSoft
/// con el color primario corporativo.
///
/// Características:
/// - Texto "CastaSoft" en color primario
/// - Tipografía Poppins Bold para impacto visual
/// - Tamaño adaptado para encabezados
///
/// Uso:
/// ```dart
/// const LogoMarca()
/// ```
class LogoMarca extends StatelessWidget {
  /// Constructor del componente LogoMarca
  const LogoMarca({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      'CastaSoft',
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1E3A8A), // Azul Marino Oscuro (Color Primario)
      ),
    );
  }
}
