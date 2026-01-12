import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';

class TarjetaGallo extends StatelessWidget {
  final Gallo gallo;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  // 🔥 NUEVO CALLBACK PARA EL PEDIGREE
  final VoidCallback? onPedigree; 

  const TarjetaGallo({
    Key? key,
    required this.gallo,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPedigree, // Recibimos la función aquí
  }) : super(key: key);

  // --- LÓGICA DE EDAD ---
  String _calcularEdadBonita(DateTime nacimiento) {
    final ahora = DateTime.now();
    int anos = ahora.year - nacimiento.year;
    int meses = ahora.month - nacimiento.month;
    int dias = ahora.day - nacimiento.day;

    if (meses < 0 || (meses == 0 && dias < 0)) {
      anos--;
      meses += 12;
    }
    if (dias < 0) {
      meses--;
      if (meses < 0) meses += 12;
    }
    if (anos == 0) return '$meses meses';
    if (meses == 0) return '$anos años';
    return '$anos años, $meses m';
  }

  void _mostrarImagenGrande(BuildContext context, ImageProvider imagen) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
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
    Widget widgetImagen;
    ImageProvider? proveedorImagen;

    if (gallo.fotoPath != null && gallo.fotoPath!.startsWith('base64,')) {
      try {
        final String base64String = gallo.fotoPath!.split(',').last;
        final bytes = base64Decode(base64String);
        proveedorImagen = MemoryImage(bytes);
        widgetImagen = Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        widgetImagen = const Icon(Icons.broken_image, color: Colors.grey);
      }
    } else {
      widgetImagen = const Icon(FontAwesomeIcons.kiwiBird, size: 30, color: Color(0xFF1E3A8A));
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // PARTE SUPERIOR (FOTO + DATOS)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FOTO
                GestureDetector(
                  onTap: proveedorImagen != null 
                      ? () => _mostrarImagenGrande(context, proveedorImagen!) 
                      : null,
                  child: Container(
                    width: 90, 
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: proveedorImagen != null 
                          ? widgetImagen
                          : Center(child: widgetImagen),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // DETALLES
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título y Estado
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
                          const SizedBox(width: 8),
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

                      // EDAD
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.cakeCandles, size: 10, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _calcularEdadBonita(gallo.fechaNacimiento),
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // PLACA Y PESO
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFD4AF37)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Placa: ${gallo.placa}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD4AF37),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 10),
                          
                          if (gallo.pesoActual != null) ...[
                            const Icon(FontAwesomeIcons.weightScale, size: 10, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${gallo.pesoActual} Lbs',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ]
                        ],
                      ),
                      
                      const SizedBox(height: 8),

                      // Botones de acción (Editar / Borrar) alineados a la derecha
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                            InkWell(
                              onTap: onEdit,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Icon(FontAwesomeIcons.pencil, size: 14, color: Colors.blue.shade800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: onDelete,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
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

            const SizedBox(height: 10),
            // 🔥 NUEVO BOTÓN GRANDE PARA GENERAR PEDIGREE
            // Está fuera del Row principal para ocupar el ancho completo
            if (onPedigree != null) 
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onPedigree,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37), // Dorado
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.workspace_premium, size: 20),
                  label: Text("CERTIFICADO PEDIGREE", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
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
