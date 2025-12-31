import 'dart:convert'; // IMPORTANTE: Para leer el texto de la foto
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';

class TarjetaGallo extends StatelessWidget {
  final Gallo gallo;
  final VoidCallback? onTap; // Para dar click a la tarjeta entera
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TarjetaGallo({
    Key? key,
    required this.gallo,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  // FUNCIÓN PARA EL ZOOM (Pantalla completa) 🔍
  void _mostrarImagenGrande(BuildContext context, ImageProvider imagen) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9), // Fondo oscuro
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer( // Permite pellizcar para zoom
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image(image: imagen, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. PREPARAMOS LA IMAGEN INTELIGENTE 🧠
    Widget widgetImagen;
    ImageProvider? proveedorImagen;

    if (gallo.fotoPath != null && gallo.fotoPath!.startsWith('base64,')) {
      try {
        // Es texto Base64: Lo convertimos a imagen
        final String base64String = gallo.fotoPath!.split(',').last;
        final bytes = base64Decode(base64String);
        proveedorImagen = MemoryImage(bytes);
        widgetImagen = Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        widgetImagen = const Icon(Icons.broken_image, color: Colors.grey);
      }
    } else {
      // No hay foto
      widgetImagen = const Icon(FontAwesomeIcons.kiwiBird, size: 30, color: Color(0xFF1E3A8A));
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bordes más suaves
      elevation: 4, // Un poco más de sombra
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // === FOTO CUADRADA GRANDE (Click para Zoom) ===
            GestureDetector(
              onTap: proveedorImagen != null 
                  ? () => _mostrarImagenGrande(context, proveedorImagen!) 
                  : null,
              child: Container(
                width: 100, // TAMAÑO GRANDE
                height: 100, // CUADRADO
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12), // Bordes redondeados pero cuadrado
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: proveedorImagen != null 
                      ? widgetImagen // Muestra la foto
                      : Center(child: widgetImagen), // Muestra el icono centrado
                ),
              ),
            ),

            const SizedBox(width: 16),

            // === DETALLES ===
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título y Menú
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          gallo.nombre,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Badge Estado
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _colorFondoEstado(gallo.estado),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          gallo.estado,
                          style: GoogleFonts.poppins(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            color: _colorTextoEstado(gallo.estado),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    'Placa: ${gallo.placa}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD4AF37), // Dorado
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Botones de acción alineados a la derecha
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                       // Botón Editar
                       InkWell(
                         onTap: onEdit,
                         child: Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                           child: Icon(FontAwesomeIcons.pencil, size: 14, color: Colors.blue.shade800),
                         ),
                       ),
                       const SizedBox(width: 10),
                       // Botón Eliminar
                       InkWell(
                         onTap: onDelete,
                         child: Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                           child: Icon(FontAwesomeIcons.trash, size: 14, color: Colors.red.shade800),
                         ),
                       ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorFondoEstado(String estado) {
    switch (estado) {
      case 'Activo': return Colors.green.shade50;
      case 'Vendido': return Colors.blue.shade50;
      case 'Retirado': return Colors.red.shade50;
      default: return Colors.grey.shade100;
    }
  }

  Color _colorTextoEstado(String estado) {
    switch (estado) {
      case 'Activo': return Colors.green.shade700;
      case 'Vendido': return Colors.blue.shade700;
      case 'Retirado': return Colors.red.shade700;
      default: return Colors.grey.shade700;
    }
  }
}
