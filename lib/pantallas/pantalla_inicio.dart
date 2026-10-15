import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

// Importaciones de tus archivos
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/servicios/servicio_firestore.dart';
import 'package:castasoft/componentes/tarjeta_gallo.dart';
import 'package:castasoft/componentes/icono_adaptativo.dart';
import 'package:castasoft/pantallas/pantalla_formulario_gallo.dart';
import 'package:castasoft/pantallas/pantalla_detalle_gallo.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart';
import 'package:castasoft/pantallas/pantalla_lista_cruces.dart';
import 'package:castasoft/pantallas/pantalla_configuracion_perfil.dart';
import 'package:castasoft/pantallas/pantalla_centro_seguridad.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  late TextEditingController _buscarController;
  
  // Variables de estado para los filtros
  String _filtroEstadoSeleccionado = 'Todos'; 
  String _filtroEtapaSeleccionado = 'Todas';  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GallosProveedor>().cargarGallos();
      context.read<UsuarioProveedor>().cargarPerfil();
    });
    _buscarController = TextEditingController();
  }

  @override
  void dispose() {
    _buscarController.dispose();
    super.dispose();
  }

  // --- LÓGICA PARA CERRAR SESIÓN (INTACTA) ---
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
        content: Text('¿Estás seguro de que deseas salir de CastaSoft?', style: GoogleFonts.poppins()),
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
      final servicio = context.read<ServicioFirestore>();
      final navigator = Navigator.of(context);
      await servicio.cerrarSesion();
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // SafeArea + Column asegura que el encabezado no se corte en iPhone o Android con Notch
      body: SafeArea(
        child: Column(
          children: [
            // 1. ENCABEZADO RESPONSIVE
            _construirEncabezado(context),

            // 2. BARRA DE FILTROS (CHIPS)
            _construirBarraFiltros(),

            // 3. CONTENIDO CON SCROLL
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
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PantallaFormularioGallo()),
          );
        },
        backgroundColor: const Color(0xFFD4AF37),
        elevation: 4,
        tooltip: 'Registrar Nuevo Gallo',
        child: const FaIcon(FontAwesomeIcons.plus, color: Color(0xFF1E3A8A)),
      ),
    );
  }

  // ===========================================================================
  // 🧩 ENCABEZADO RESPONSIVE
  // ===========================================================================

  Widget _construirEncabezado(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      // LayoutBuilder detecta el ancho de la pantalla
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool esPantallaAncha = constraints.maxWidth > 700; // Tablet o PC

          if (esPantallaAncha) {
            // Fila única para pantallas grandes
            return Row(
              children: [
                _buildPerfilClickeable(context),
                const Spacer(),
                _buildBuscador(ancho: 350), 
                const SizedBox(width: 15),
                _buildFiltroEstado(),
                const SizedBox(width: 15),
                _buildBotonSalir(),
              ],
            );
          } else {
            // Columna (2 filas) para celulares
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildPerfilClickeable(context),
                    const Spacer(),
                    _buildBotonSalir(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildBuscador(ancho: double.infinity)),
                    const SizedBox(width: 10),
                    _buildFiltroEstado(compacto: true),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

 // 🔥 BARRA DE FILTROS DESLIZABLE (CHIPS)
  Widget _construirBarraFiltros() {
    // Escuchamos al proveedor para saber si hay que mostrar el chip de advertencia
    final requiereAct = context.watch<GallosProveedor>().requiereActualizacionEtapa;
    
    // Lista con los nombres NUEVOS
    final List<String> etapas = ['Todas', ...Gallo.etapasVida];
    
    // Si hay gallos viejos, insertamos el chip rojo en la segunda posición
    if (requiereAct) {
      etapas.insert(1, '⚠️ Actualizar'); 
    }

    return Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: etapas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final etapa = etapas[index];
          final estaSeleccionado = _filtroEtapaSeleccionado == etapa;
          final esAdvertencia = etapa == '⚠️ Actualizar';

          return ChoiceChip(
            label: Text(
              etapa,
              style: TextStyle(
                color: estaSeleccionado ? Colors.white : (esAdvertencia ? Colors.red.shade700 : const Color(0xFF1E3A8A)),
                fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            selected: estaSeleccionado,
            // Color especial si es el chip de advertencia
            selectedColor: esAdvertencia ? Colors.red.shade600 : const Color(0xFF1E3A8A),
            backgroundColor: esAdvertencia ? Colors.red.shade50 : const Color(0xFFF1F5F9),
            side: esAdvertencia ? BorderSide(color: Colors.red.shade200) : null,
            onSelected: (bool selected) {
              setState(() {
                _filtroEtapaSeleccionado = selected ? etapa : 'Todas';
              });
              context.read<GallosProveedor>().setFiltroEtapa(_filtroEtapaSeleccionado);
              
              // 🔥 TU IDEA: Mensaje flotante explicativo
              if (selected && esAdvertencia) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Las etapas "${Gallo.etapasLegadas.join('" y "')}" se han cambiado. Por favor, edita estos animales y asígnales una nueva etapa.')),
                      ],
                    ),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 🧩 CONTENIDO DASHBOARD
  // ===========================================================================

  Widget _construirContenidoDashboard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _construirSeccionEstadisticas(),
          const SizedBox(height: 20),
          _buildTarjetaModuloCruces(),
          const SizedBox(height: 25),
          _construirSeccionListaReciente(),
        ],
      ),
    );
  }

  // 🔥 TARJETAS DE ESTADÍSTICAS (Activos y Vendidos)
  Widget _construirSeccionEstadisticas() {
    return Consumer<GallosProveedor>(
      builder: (context, gallosProveedor, child) {
        final conteoDetallado = gallosProveedor.obtenerConteoDetallado();
        final estadisticasGenerales = gallosProveedor.obtenerEstadisticas();

        return Column(
          children: [
            // 1. TARJETA AZUL (ACTIVOS + DESGLOSE)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  // Fila Superior
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Activos', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
                          Text(
                            '${conteoDetallado['total']}',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        // CAMBIO DE ICONO: Pluma en vez de KiwiBird
                        child: const FaIcon(FontAwesomeIcons.featherPointed, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  // Fila Inferior (Desglose)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniDato('Padrotes', '${conteoDetallado['padrotes']}', FontAwesomeIcons.mars),
                      _buildMiniDato('Madrillas', '${conteoDetallado['madrillas']}', FontAwesomeIcons.venus),
                      _buildMiniDato('Cría', '${conteoDetallado['crias']}', FontAwesomeIcons.egg),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. TARJETA DORADA (VENDIDOS) - RESTAURADO COLOR ORIGINAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFF59E0B)], // Dorado original
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD4AF37).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Vendidos', style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.9), fontSize: 14)),
                      Text(
                        '${estadisticasGenerales['vendidos']}',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const FaIcon(FontAwesomeIcons.sackDollar, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniDato(String label, String valor, dynamic icono) {
    return Column(
      children: [
        IconoAdaptativo(icono, color: Colors.white70, size: 14),
        const SizedBox(height: 4),
        Text(valor, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10)),
      ],
    );
}

  // TARJETA CRUCES
  Widget _buildTarjetaModuloCruces() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaListaCruces())),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF059669).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cruces y Genética', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('Gestiona camadas, padres y nacimientos', style: TextStyle(color: Colors.white70, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 2),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const FaIcon(FontAwesomeIcons.dna, color: Colors.white, size: 24),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _filtroEtapaSeleccionado == "Todas" ? 'Inventario Completo' : 'Lista de $_filtroEtapaSeleccionado',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A)),
                ),
                Text('${gallos.length} resultados', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 16),
            if (gallos.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Center(
                  child: Column(
                    children: [
                      // Cambio de icono aquí también si quieres
                      FaIcon(FontAwesomeIcons.featherPointed, size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text('No se encontraron gallos', style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: gallos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final gallo = gallos[index];
                  return GestureDetector(
                    onTap: () => _navegarADetalleGallo(context, gallo),
                    child: TarjetaGallo(
                      gallo: gallo,
                      // La lista se actualiza sola por el stream en tiempo real
                      onEdit: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PantallaFormularioGallo(galloEditar: gallo)),
                      ),
                      onDelete: () => _mostrarConfirmacionEliminar(context, gallo),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  // --- HELPERS Y PERFIL ---

   Widget _buildPerfilClickeable(BuildContext context) {
    return Consumer<UsuarioProveedor>(
      builder: (context, usuarioProv, child) {
        final perfil = usuarioProv.perfil;
        
        // 🔥 NUEVO: Menú desplegable al tocar el perfil
        void abrirMenuPerfil() {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (BuildContext ctx) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    // Pequeña barra gris indicadora de que se puede arrastrar
                    Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 10),
                    
                    // Opción 1: Editar Perfil
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.userPen, color: Color(0xFF1E3A8A)),
                      title: const Text('Editar Perfil de Criador', style: TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        Navigator.pop(ctx); // Cierra el menú
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaConfiguracionPerfil(perfilEditar: perfil)));
                      },
                    ),
                    const Divider(height: 1),
                    
                    // Opción 2: Centro de Seguridad
                    ListTile(
                      leading: FaIcon(FontAwesomeIcons.shieldHalved, color: Colors.green.shade600),
                      title: const Text('Centro de Seguridad y Reportes', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Copias de seguridad y exportación'),
                      onTap: () {
                        Navigator.pop(ctx); // Cierra el menú
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCentroSeguridad()));
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
          );
        }

        // Logo memoizado en el modelo: no se decodifica Base64 en cada rebuild
        final logoBytes = perfil?.logoBytes;
        final Widget widgetLogo = logoBytes != null
            ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(logoBytes, height: 45, width: 45, fit: BoxFit.cover, gaplessPlayback: true))
            : _logoIcono();

        return InkWell(
          onTap: abrirMenuPerfil, // 🔥 Ahora abre el menú en vez de ir directo a editar
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5)),
                child: widgetLogo,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(perfil?.nombreCastadero ?? 'Mi Criadero', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
                  Text(perfil?.nombrePropietario ?? 'Propietario', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBuscador({required double ancho}) {
    return SizedBox(
      width: ancho,
      height: 40,
      child: TextField(
        controller: _buscarController,
        decoration: InputDecoration(
          hintText: 'Buscar placa, nombre...',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: const IconoAdaptativo.prefijo(FontAwesomeIcons.magnifyingGlass, size: 14, color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        onChanged: (value) => context.read<GallosProveedor>().setFiltroTexto(value),
      ),
    );
  }

  Widget _buildFiltroEstado({bool compacto = false}) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filtroEstadoSeleccionado,
          icon: const Icon(Icons.filter_list, size: 18, color: Colors.grey),
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
          items: ['Todos', ...Gallo.estadosValidos].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
          onChanged: (val) {
            context.read<GallosProveedor>().setFiltroEstado(val ?? 'Todos');
            setState(() => _filtroEstadoSeleccionado = val ?? 'Todos');
          },
        ),
      ),
    );
  }

  Widget _buildBotonSalir() {
    return InkWell(
      onTap: _confirmarCierreSesion,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
        child: FaIcon(FontAwesomeIcons.rightFromBracket, size: 16, color: Colors.red.shade400),
      ),
    );
  }

  Future<void> _navegarADetalleGallo(BuildContext context, Gallo gallo) async {
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => PantallaDetalleGallo(gallo: gallo)),
    );
    if (!context.mounted) return;
    if (resultado == 'editar') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaFormularioGallo(galloEditar: gallo)));
    } else if (resultado == 'eliminar') {
      _mostrarConfirmacionEliminar(context, gallo);
    }
  }

  Future<void> _mostrarConfirmacionEliminar(BuildContext context, Gallo gallo) async {
    // Se capturan antes de cualquier await (contexto asíncrono seguro)
    final gallosProv = context.read<GallosProveedor>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro que desea eliminar a ${gallo.nombre}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final confirmado = await gallosProv.eliminarGallo(gallo.id);
        messenger.showSnackBar(SnackBar(
          content: Text(confirmado
              ? 'Eliminado correctamente'
              : 'Eliminado sin conexión: se sincronizará al volver el internet'),
          backgroundColor: confirmado ? Colors.green : Colors.orange.shade800,
        ));
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Widget _logoIcono() {
    return Container(
      width: 45, height: 45,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: const FaIcon(FontAwesomeIcons.houseUser, color: Color(0xFF1E3A8A), size: 20),
    );
  }
}