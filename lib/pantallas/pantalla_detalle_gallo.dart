import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';

/// Pantalla de Detalle del Gallo
///
/// Muestra un perfil completo y profesional del gallo con:
/// - Foto, nombre, placa y estado
/// - Resumen de datos clave (sexo, edad, peso, jaula)
/// - Información genética (línea y color)
/// - Genealogía (padre y madre)
/// - Datos de origen (fecha nacimiento, fase lunar, criadero)
/// - Notas (si las hay)
class PantallaDetalleGallo extends StatelessWidget {
  /// Gallo a mostrar
  final Gallo gallo;

  const PantallaDetalleGallo({Key? key, required this.gallo}) : super(key: key);

  /// Calcula la edad del gallo en meses
  int _calcularEdadMeses(DateTime fechaNacimiento) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fechaNacimiento).inDays;
    return (diferencia / 30).round();
  }

  /// Formatea una fecha al formato DD/MM/YYYY
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  /// Obtiene el nombre del padre o "Desconocido"
  String _obtenerNombrePadre(BuildContext context) {
    if (gallo.padreId == null && gallo.idPadre == null) {
      return 'Desconocido';
    }
    final padreId = gallo.padreId ?? gallo.idPadre;
    try {
      final gallosProveedor = context.read<GallosProveedor>();
      final padre = gallosProveedor.gallos.firstWhere(
        (g) => g.id == padreId,
        orElse: () => Gallo(
          id: 'notfound',
          placa: '',
          nombre: 'Desconocido',
          sexo: 'Macho',
          fechaNacimiento: DateTime.now(),
          lineaGenetica: '',
          colorPluma: '',
          faseLunar: '',
          estado: 'Activo',
        ),
      );
      return padre.id == 'notfound' ? 'Desconocido' : padre.nombre;
    } catch (_) {
      return 'Desconocido';
    }
  }

  /// Obtiene el nombre de la madre o "Desconocido"
  String _obtenerNombreMadre(BuildContext context) {
    if (gallo.madreId == null && gallo.idMadre == null) {
      return 'Desconocido';
    }
    final madreId = gallo.madreId ?? gallo.idMadre;
    try {
      final gallosProveedor = context.read<GallosProveedor>();
      final madre = gallosProveedor.gallos.firstWhere(
        (g) => g.id == madreId,
        orElse: () => Gallo(
          id: 'notfound',
          placa: '',
          nombre: 'Desconocido',
          sexo: 'Hembra',
          fechaNacimiento: DateTime.now(),
          lineaGenetica: '',
          colorPluma: '',
          faseLunar: '',
          estado: 'Activo',
        ),
      );
      return madre.id == 'notfound' ? 'Desconocido' : madre.nombre;
    } catch (_) {
      return 'Desconocido';
    }
  }

  /// Color de badge según el estado
  Color _obtenerColorEstado(String estado) {
    switch (estado) {
      case 'Activo':
        return const Color(0xFF10B981);
      case 'Vendido':
        return const Color(0xFF6366F1);
      case 'Retirado':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final edadMeses = _calcularEdadMeses(gallo.fechaNacimiento);

    return Scaffold(
      appBar: AppBar(
        title: Text(gallo.nombre),
        backgroundColor: const Color(0xFF1E3A8A),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(FontAwesomeIcons.pen, size: 16),
                    SizedBox(width: 12),
                    Text('Editar'),
                  ],
                ),
                onTap: () => Navigator.pop(context, 'editar'),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () => Navigator.pop(context, 'eliminar'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ==================== ENCABEZADO: FOTO, NOMBRE, PLACA Y ESTADO ====================
            Container(
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    /// Foto circular
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: gallo.fotoPath != null
                              ? Image.file(
                                  File(gallo.fotoPath!),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(
                                    FontAwesomeIcons.image,
                                    size: 64,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    /// Nombre y placa
                    Text(
                      gallo.nombre,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placa: ${gallo.placa}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _obtenerColorEstado(gallo.estado),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        gallo.estado,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// ==================== SECCIÓN RESUMEN: ICONOS Y DATOS CLAVE ====================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  /// Sexo
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Icon(
                              gallo.sexo == 'Macho'
                                  ? FontAwesomeIcons.mars
                                  : FontAwesomeIcons.venus,
                              size: 24,
                              color: const Color(0xFF1E3A8A),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gallo.sexo,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  /// Edad
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Icon(
                              FontAwesomeIcons.calendar,
                              size: 24,
                              color: Color(0xFF1E3A8A),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$edadMeses meses',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  /// Peso
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Icon(
                              FontAwesomeIcons.weightHanging,
                              size: 24,
                              color: Color(0xFF1E3A8A),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gallo.peso != null ? '${gallo.peso} kg' : 'N/A',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  /// Jaula
                  Expanded(
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Icon(
                              FontAwesomeIcons.box,
                              size: 24,
                              color: Color(0xFF1E3A8A),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              gallo.jaula ?? 'N/A',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  /// ==================== TARJETA: GENÉTICA ====================
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Genética',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Línea Genética',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      gallo.lineaGenetica,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Color de Pluma',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      gallo.colorPluma,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// ==================== TARJETA: GENEALOGÍA ====================
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Genealogía',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          FontAwesomeIcons.mars,
                                          size: 14,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Padre',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _obtenerNombrePadre(context),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          FontAwesomeIcons.venus,
                                          size: 14,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Madre',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _obtenerNombreMadre(context),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// ==================== TARJETA: ORIGEN ====================
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Origen',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha Nacimiento',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatearFecha(gallo.fechaNacimiento),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fase Lunar',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      gallo.faseLunar,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Criadero Origen',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                gallo.criaderoOrigen,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// ==================== TARJETA: NOTAS ====================
                  if (gallo.notas != null && gallo.notas!.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notas',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              gallo.notas!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF475569),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
