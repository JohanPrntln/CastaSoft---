import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Componente TarjetaKPI - Tarjeta de indicador clave de desempeño
///
/// Widget reutilizable que muestra un KPI (Key Performance Indicator)
/// con un diseño limpio, moderno y minimalista.
///
/// Características:
/// - Tarjeta con esquinas redondeadas
/// - Sombra sutil para profundidad
/// - Fondo personalizable con colores corporativos
/// - Título descriptivo y valor numérico
/// - Responsive para diferentes tamaños de pantalla
///
/// Parámetros:
/// - [titulo] - Nombre del indicador (ej: "Gallos Activos")
/// - [valor] - Número a mostrar (ej: 15)
/// - [colorFondo] - Color de fondo de la tarjeta
///
/// Uso:
/// ```dart
/// TarjetaKPI(
///   titulo: 'Gallos Activos',
///   valor: 25,
///   colorFondo: Colors.blue.withOpacity(0.1),
/// )
/// ```
class TarjetaKPI extends StatelessWidget {
  /// Título del indicador
  final String titulo;

  /// Valor numérico a mostrar
  final int valor;

  /// Color de fondo de la tarjeta
  final Color colorFondo;

  /// Icono representativo opcional
  final IconData? icono;

  /// Constructor del componente TarjetaKPI
  const TarjetaKPI({
    Key? key,
    required this.titulo,
    required this.valor,
    required this.colorFondo,
    this.icono,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colores corporativos
    const dorado = Color(0xFFD4AF37);
    const azulMarino = Color(0xFF1E3A8A);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título en la parte superior
            Text(
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 10),

            // Valor con icono a la derecha
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Número destacado
                Text(
                  valor.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: azulMarino,
                  ),
                ),

                const SizedBox(width: 12),

                // Icono representativo en dorado
                if (icono != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icono, size: 18, color: dorado),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
