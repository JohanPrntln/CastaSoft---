import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

// Importaciones de tus archivos
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/servicios/servicio_firestore.dart';
import 'package:castasoft/componentes/tarjeta_gallo.dart';
import 'package:castasoft/pantallas/pantalla_formulario_gallo.dart';
import 'package:castasoft/pantallas/pantalla_detalle_gallo.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart';
import 'package:castasoft/pantallas/pantalla_lista_cruces.dart';
import 'package:castasoft/pantallas/pantalla_configuracion_perfil.dart';
import 'package:castasoft/servicios/servicio_firestore.dart';


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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<GallosProveedor>().cargarGallos();
      await context.read<UsuarioProveedor>().cargarPerfil();
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
            Text(
              'Cerrar Sesión',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas salir de CastaSoft?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Sí, Salir',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await context.read<ServicioFirestore>().cerrarSesion();
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // 🔥 CAMBIO IMPORTANTE: Quitamos 'appBar' y usamos SafeArea + Column
      // Esto permite que el encabezado cambie de tamaño sin romper la pantalla.
      body: SafeArea(
        child: Column(
          children: [
            // 1. EL ENCABEZADO RESPONSIVE (Se ajusta solo)
            _construirEncabezado(context),

            // 2. EL RESTO DE LA PANTALLA (CON SCROLL)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [_construirContenidoDashboard(context)],
                ),
              ),
            ),
          ],
        ),
      ),

      // BOTÓN FLOTANTE
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PantallaFormularioGallo(),
            ),
          );
        },
        backgroundColor: const Color(0xFFD4AF37), // Dorado Premium
        elevation: 4,
        tooltip: 'Registrar Nuevo Gallo',
        child: const Icon(FontAwesomeIcons.plus, color: Color(0xFF1E3A8A)),
      ),
    );
  }

  // ===========================================================================
  // 🧩 SECCIÓN DE ENCABEZADO RESPONSIVO (LAYOUT BUILDER)
  // ===========================================================================

  Widget _construirEncabezado(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Si el ancho es mayor a 700px, es Tablet/PC
          bool esPantallaAncha = constraints.maxWidth > 700;

          if (esPantallaAncha) {
            // 🖥️ MODO ESCRITORIO (1 FILA)
            return Row(
              children: [
                _buildPerfilClickeable(context),
                const Spacer(),
                _buildBuscador(ancho: 350), // Barra larga
                const SizedBox(width: 15),
                _buildFiltro(),
                const SizedBox(width: 15),
                _buildBotonSalir(),
              ],
            );
          } else {
            // 📱 MODO CELULAR (2 FILAS)
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila 1: Logo y Salir
                Row(
                  children: [
                    _buildPerfilClickeable(context),
                    const Spacer(),
                    _buildBotonSalir(),
                  ],
                ),
                const SizedBox(height: 12),
                // Fila 2: Buscador y Filtro
                Row(
                  children: [
                    Expanded(child: _buildBuscador(ancho: double.infinity)),
                    const SizedBox(width: 10),
                    _buildFiltro(compacto: true),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // --- PIEZAS DEL ENCABEZADO ---

  // 1. PERFIL
  Widget _buildPerfilClickeable(BuildContext context) {
    return Consumer<UsuarioProveedor>(
      builder: (context, usuarioProv, child) {
        final perfil = usuarioProv.perfil;

        void irAEditar() {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaConfiguracionPerfil(perfilEditar: perfil),
            ),
          );
        }

        Widget widgetLogo;
        if (perfil?.logoPath != null &&
            perfil!.logoPath!.startsWith('base64,')) {
          try {
            final bytes = base64Decode(perfil.logoPath!.split(',').last);
            widgetLogo = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              ),
            );
          } catch (e) {
            widgetLogo = _logoIcono();
          }
        } else {
          widgetLogo = _logoIcono();
        }

        return InkWell(
          onTap: irAEditar,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: widgetLogo,
              ),
              const SizedBox(width: 12),

              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      perfil?.nombreCastadero ?? 'Mi Criadero',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                      maxLines: 2, // Permite 2 líneas
                      overflow: TextOverflow.visible,
                    ),
                    Row(
                      children: [
                        Text(
                          perfil?.nombrePropietario ?? 'Propietario',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit,
                          size: 10,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. BUSCADOR
  Widget _buildBuscador({required double ancho}) {
    return Container(
      width: ancho,
      height: 45,
      child: TextField(
        controller: _buscarController,
        decoration: InputDecoration(
          hintText: 'Buscar placa, nombre, padre...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
          prefixIcon: const Icon(
            FontAwesomeIcons.magnifyingGlass,
            size: 16,
            color: Colors.grey,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 15,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        onChanged: (value) =>
            context.read<GallosProveedor>().setFiltroTexto(value),
      ),
    );
  }

  // 3. FILTRO
  Widget _buildFiltro({bool compacto = false}) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filtroSeleccionado,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: ['Todos', 'Activo', 'Vendido', 'Retirado'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (val) {
            context.read<GallosProveedor>().setFiltroEstado(val ?? 'Todos');
            setState(() => _filtroSeleccionado = val ?? 'Todos');
          },
        ),
      ),
    );
  }

  // 4. BOTÓN SALIR
  Widget _buildBotonSalir() {
    return Tooltip(
      message: 'Cerrar Sesión',
      child: InkWell(
        onTap: _confirmarCierreSesion,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            FontAwesomeIcons.rightFromBracket,
            size: 18,
            color: Colors.red.shade400,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 🧩 CONTENIDO DEL DASHBOARD
  // ===========================================================================

  Widget _construirContenidoDashboard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirSeccionEstadisticas(),
          const SizedBox(height: 20),
          _buildTarjetaModuloCruces(),
          const SizedBox(height: 30),
          _construirSeccionListaReciente(),
        ],
      ),
    );
  }

  // ESTADÍSTICAS (Activos / Vendidos)
  Widget _construirSeccionEstadisticas() {
    return Consumer<GallosProveedor>(
      builder: (context, gallosProveedor, child) {
        final estadisticas = gallosProveedor.obtenerEstadisticas();
        return Row(
          children: [
            Expanded(
              child: _buildTarjetaResumen(
                titulo: 'Activos',
                valor: estadisticas['activos'] ?? 0,
                icono: FontAwesomeIcons.kiwiBird,
                colores: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTarjetaResumen(
                titulo: 'Vendidos',
                valor: estadisticas['vendidos'] ?? 0,
                icono: FontAwesomeIcons.sackDollar,
                colores: [const Color(0xFFD4AF37), const Color(0xFFF59E0B)],
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper Tarjeta Resumen
  Widget _buildTarjetaResumen({
    required String titulo,
    required int valor,
    required IconData icono,
    required List<Color> colores,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colores,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colores.first.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 15),
          Text(
            valor.toString(),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  // TARJETA CRUCES (Verde)
  Widget _buildTarjetaModuloCruces() {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaListaCruces()));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF34D399)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: const Color(0xFF059669).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🔥 CAMBIO CLAVE: Expanded atrapa el texto para que no empuje
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cruces y Genética',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  // 🔥 CAMBIO CLAVE: Agregamos overflow para cortar si es muy largo
                  Text(
                    'Gestiona camadas, padres y nacimientos',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis, // Pone "..." si no cabe
                    maxLines: 2, // Permite que baje máximo a 2 renglones
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15), // Un respiro entre texto e icono
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              // El icono ahora nunca se saldrá
              child: const Icon(FontAwesomeIcons.dna, color: Colors.white, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  // LISTA DE GALLOS
  Widget _construirSeccionListaReciente() {
    return Consumer<GallosProveedor>(
      builder: (context, gallosProveedor, child) {
        final gallos = gallosProveedor.gallosFiltrados;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventario Reciente',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            if (gallos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        FontAwesomeIcons.kiwiBird,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No hay gallos registrados aún',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gallos.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final gallo = gallos[index];
                  return GestureDetector(
                    onTap: () => _navegarADetalleGallo(context, gallo),
                    child: TarjetaGallo(
                      gallo: gallo,
                      onEdit: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PantallaFormularioGallo(galloEditar: gallo),
                          ),
                        ).then(
                          (_) => context.read<GallosProveedor>().cargarGallos(),
                        );
                      },
                      onDelete: () =>
                          _mostrarConfirmacionEliminar(context, gallo),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // ... MÉTODOS DE NAVEGACIÓN Y HELPERS ...
  Future<void> _navegarADetalleGallo(BuildContext context, Gallo gallo) async {
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaDetalleGallo(gallo: gallo),
      ),
    );

    if (resultado == 'editar' && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaFormularioGallo(galloEditar: gallo),
        ),
      ).then((_) => context.read<GallosProveedor>().cargarGallos());
    } else if (resultado == 'eliminar' && mounted) {
      _mostrarConfirmacionEliminar(context, gallo);
    }
  }

  Future<void> _mostrarConfirmacionEliminar(
    BuildContext context,
    Gallo gallo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Está seguro que desea eliminar a ${gallo.nombre}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      try {
        await context.read<GallosProveedor>().eliminarGallo(gallo.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ✅ ESTE ES EL ICONO QUE DABA ERROR (AHORA SOLO APARECE UNA VEZ AQUÍ)
  Widget _logoIcono() {
    return Container(
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        FontAwesomeIcons.houseUser,
        color: Color(0xFF1E3A8A),
        size: 24,
      ),
    );
  }
}
