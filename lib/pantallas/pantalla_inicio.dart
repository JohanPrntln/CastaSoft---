import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

// Importaciones de tus archivos
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/servicios/servicio_firestore.dart';
import 'package:castasoft/componentes/tarjeta_kpi.dart';
import 'package:castasoft/componentes/tarjeta_gallo.dart';
import 'package:castasoft/pantallas/pantalla_formulario_gallo.dart';
import 'package:castasoft/pantallas/pantalla_detalle_gallo.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart'; // IMPORTANTE: Para el logo y perfil

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({Key? key}) : super(key: key);

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  late TextEditingController _buscarController;
  String _filtroSeleccionado = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GallosProveedor>().cargarGallos();
    });
    _buscarController = TextEditingController();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  // --- LÓGICA PARA CERRAR SESIÓN ---
  Future<void> _confirmarCierreSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Text('Cerrar Sesión', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas salir de CastaSoft?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sí, Salir', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await context.read<ServicioFirestore>().cerrarSesion();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      
      // ENCABEZADO SUPERIOR (Ahora más limpio)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _construirEncabezado(context),
      ),

      // CUERPO DE LA PANTALLA
      body: SingleChildScrollView(
        child: Column(
          children: [
            _construirContenidoDashboard(context),
          ],
        ),
      ),

      // 🔥 AQUÍ ESTÁ EL NUEVO BOTÓN FLOTANTE 🔥
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => const PantallaFormularioGallo())
          );
        },
        backgroundColor: const Color(0xFFD4AF37), // Dorado Premium
        elevation: 4,
        tooltip: 'Registrar Nuevo Gallo',
        child: const Icon(FontAwesomeIcons.plus, color: Color(0xFF1E3A8A)), // Icono Azul Marino
      ),
    );
  }

  // ... MÉTODOS DE NAVEGACIÓN (Sin cambios) ...
  Future<void> _navegarADetalleGallo(BuildContext context, Gallo gallo) async {
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => PantallaDetalleGallo(gallo: gallo)),
    );

    if (resultado == 'editar' && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PantallaFormularioGallo(galloEditar: gallo)),
      ).then((_) => context.read<GallosProveedor>().cargarGallos());
    } else if (resultado == 'eliminar' && mounted) {
      _mostrarConfirmacionEliminar(context, gallo);
    }
  }

  Future<void> _mostrarConfirmacionEliminar(BuildContext context, Gallo gallo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Está seguro que desea eliminar a ${gallo.nombre}?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      try {
        await context.read<GallosProveedor>().eliminarGallo(gallo.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminado correctamente'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Widget _construirEncabezado(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // ===============================================
              // 🔥 LOGO INTELIGENTE (PERSONALIZADO) 🔥
              // ===============================================
              Consumer<UsuarioProveedor>(
                builder: (context, usuarioProv, child) {
                  final perfil = usuarioProv.perfil;

                  // CASO 1: Si tiene logo personalizado en Base64
                  if (perfil?.logoPath != null && perfil!.logoPath!.startsWith('base64,')) {
                    try {
                      final bytes = base64Decode(perfil.logoPath!.split(',').last);
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(bytes, height: 45, width: 45, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 10),
                          // Si hay espacio, mostramos el nombre del castadero al lado
                          if (MediaQuery.of(context).size.width > 360) 
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  perfil!.nombreCastadero,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)
                                  ),
                                ),
                                Text(
                                  perfil.nombrePropietario,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10, color: Colors.grey
                                  ),
                                ),
                              ],
                            )
                        ],
                      );
                    } catch (e) { 
                      return _logoPorDefecto(); 
                    }
                  }

                  // CASO 2: Si NO tiene logo, pero SÍ tiene nombre configurado
                  if (perfil != null && perfil.nombreCastadero.isNotEmpty) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(FontAwesomeIcons.houseUser, color: Color(0xFF1E3A8A), size: 24),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              perfil.nombreCastadero,
                              style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  // CASO 3: Aún no carga o no tiene nada -> Logo CastaSoft
                  return _logoPorDefecto();
                },
              ),
              // ===============================================

              const SizedBox(width: 24),

              // Buscador Flexible
              Expanded(
                child: TextField(
                  controller: _buscarController,
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
                    prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 16, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade200)),
                  ),
                  onChanged: (value) => context.read<GallosProveedor>().setFiltroTexto(value),
                ),
              ),

              const SizedBox(width: 16),

              // Filtro (Compacto) - Oculto en pantallas muy pequeñas para dar espacio al logo
              if (MediaQuery.of(context).size.width > 400)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filtroSeleccionado,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                      items: ['Todos', 'Activo', 'Vendido', 'Retirado'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (val) {
                        context.read<GallosProveedor>().setFiltroEstado(val ?? 'Todos');
                        setState(() => _filtroSeleccionado = val ?? 'Todos');
                      },
                    ),
                  ),
                ),

              if (MediaQuery.of(context).size.width > 400)
                const SizedBox(width: 16),

              // DIVISOR VERTICAL
              Container(height: 30, width: 1, color: Colors.grey.shade300),
              
              const SizedBox(width: 10),

              // BOTÓN DE SALIR
              Tooltip(
                message: 'Cerrar Sesión',
                child: InkWell(
                  onTap: _confirmarCierreSesion,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      FontAwesomeIcons.rightFromBracket,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  // ... CONTENIDO DASHBOARD Y ESTADÍSTICAS (Sin cambios estructurales) ...
  Widget _construirContenidoDashboard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirSeccionEstadisticas(),
          const SizedBox(height: 40),
          _construirSeccionListaReciente(),
        ],
      ),
    );
  }

  Widget _construirSeccionEstadisticas() {
    return Consumer<GallosProveedor>(
      builder: (context, gallosProveedor, child) {
        final estadisticas = gallosProveedor.obtenerEstadisticas();
        return Row(
          children: [
            TarjetaKPI(
              titulo: 'Gallos Activos',
              valor: estadisticas['activos'] ?? 0,
              colorFondo: const Color(0xFF1E3A8A).withOpacity(0.08),
              icono: FontAwesomeIcons.circleCheck,
            ),
            const SizedBox(width: 24),
            TarjetaKPI(
              titulo: 'Gallos Vendidos',
              valor: estadisticas['vendidos'] ?? 0,
              colorFondo: const Color(0xFFD4AF37).withOpacity(0.08),
              icono: FontAwesomeIcons.sackDollar,
            ),
          ],
        );
      },
    );
  }

  Widget _construirSeccionListaReciente() {
    return Consumer<GallosProveedor>(
      builder: (context, gallosProveedor, child) {
        final gallos = gallosProveedor.gallosFiltrados;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gallos Recientes',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 16),
            if (gallos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                child: Center(
                  child: Column(
                    children: [
                      Icon(FontAwesomeIcons.kiwiBird, size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text('No hay gallos registrados aún', style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: SizedBox(
                  height: 400,
                  child: ListView.separated(
                    itemCount: gallos.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final gallo = gallos[index];
                      return GestureDetector(
                        onTap: () => _navegarADetalleGallo(context, gallo),
                        child: TarjetaGallo(
                          gallo: gallo,
                          onEdit: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaFormularioGallo(galloEditar: gallo)))
                                .then((_) => context.read<GallosProveedor>().cargarGallos());
                          },
                          onDelete: () => _mostrarConfirmacionEliminar(context, gallo),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
 // Widget auxiliar para no repetir código (Agrégalo al final de la clase PantallaInicio)
  Widget _logoPorDefecto() {
    return Image.asset(
      'assets/logo_texto_castasoft_sf.png',
      height: 40,
      fit: BoxFit.contain,
    );
  }
}