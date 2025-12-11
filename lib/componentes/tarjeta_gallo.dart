import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';

/// Tarjeta visual que muestra la información principal de un `Gallo`.
///
/// Diseño pensado para escritorio: tarjeta blanca, esquinas redondeadas
/// y layout horizontal con miniatura, detalles y estado.
class TarjetaGallo extends StatelessWidget {
  final Gallo gallo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TarjetaGallo({
    Key? key,
    required this.gallo,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Miniatura a la izquierda
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: gallo.fotoPath != null
                  ? Image.file(
                      File(gallo.fotoPath!),
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          FontAwesomeIcons.crow,
                          size: 28,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(
                        FontAwesomeIcons.crow,
                        size: 28,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
            ),

            const SizedBox(width: 16),

            // Detalles centrales
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gallo.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    gallo.placa,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD4AF37),
                    ),
                  ),
                ],
              ),
            ),

            // Estado a la derecha
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                gallo.estado,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Botón de edición (a la derecha)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(FontAwesomeIcons.pencil, size: 16),
              color: const Color(0xFF374151),
              tooltip: 'Editar',
            ),

            // Botón de eliminar (rojo)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(FontAwesomeIcons.trash, size: 16),
              color: Colors.red,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}
