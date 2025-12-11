import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';
// Logo now loaded from assets via Image.asset
import 'package:castasoft/componentes/tarjeta_kpi.dart';
import 'package:castasoft/componentes/tarjeta_gallo.dart';
import 'package:castasoft/pantallas/pantalla_formulario_gallo.dart';
import 'package:castasoft/modelos/gallo_modelo.dart';

/// Pantalla de Inicio (Dashboard) - Vista Principal de CastaSoft
///
/// Esta es la pantalla principal de la aplicación que muestra:
/// - Logo/Marca de CastaSoft
/// - Botón para agregar nuevos gallos
/// - Tarjetas KPI con estadísticas
/// - Lista de gallos recientes
///
/// Se conecta con el [GallosProveedor] para obtener datos en tiempo real
/// y actualizar la interfaz automáticamente cuando los datos cambian.
class PantallaInicio extends StatefulWidget {
  /// Constructor de la pantalla de inicio
  const PantallaInicio({Key? key}) : super(key: key);

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  // Controlador para el campo de búsqueda
  late TextEditingController _buscarController;

  // Filtro seleccionado en el dropdown
  String _filtroSeleccionado = 'Todos';

  @override
  void initState() {
    super.initState();
    // Cargar los gallos al iniciar la pantalla (no necesitamos guardar el Future)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// AppBar personalizado con altura fija para escritorio
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: _construirEncabezado(context),
      ),

      /// Fondo gris claro corporativo
      backgroundColor: const Color(0xFFF8FAFC),

      /// Cuerpo principal de la pantalla
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// ==================== CONTENIDO DEL DASHBOARD ====================
            _construirContenidoDashboard(context),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo de confirmación antes de eliminar un gallo
  Future<void> _mostrarConfirmacionEliminar(
    BuildContext context,
    Gallo gallo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Está seguro que desea eliminar el registro de ${gallo.nombre} (${gallo.placa})? Esta acción es irreversible.',
          ),
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
            SnackBar(
              content: Text('Gallo ${gallo.nombre} eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Construye el encabezado (usado como AppBar personalizado)
  Widget _construirEncabezado(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            // Logo (asset) a la izquierda
            // Logo desde assets
            Image.asset(
              'assets/logo_texto_castasoft_sf.png',
              height: 100,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 24),

            // Campo de búsqueda flexible
            Expanded(
              child: TextField(
                controller: _buscarController,
                decoration: InputDecoration(
                  hintText: 'Buscar por Placa, Nombre, Color, Edad...',
                  prefixIcon: const Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    size: 18,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                onChanged: (value) {
                  // Aplicar filtro de búsqueda en tiempo real
                  context.read<GallosProveedor>().setFiltroTexto(value);
                },
              ),
            ),

            const SizedBox(width: 16),

            // Selector de filtro
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                value: _filtroSeleccionado,
                items: const [
                  DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                  DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'Vendido', child: Text('Vendido')),
                  DropdownMenuItem(value: 'Retirado', child: Text('Retirado')),
                ],
                onChanged: (valor) {
                  // Aplicar filtro de estado
                  context.read<GallosProveedor>().setFiltroEstado(
                    valor ?? 'Todos',
                  );
                  setState(() {
                    _filtroSeleccionado = valor ?? 'Todos';
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Botón Agregar más prominente a la derecha
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PantallaFormularioGallo(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(FontAwesomeIcons.plus, size: 16),
              label: Text(
                'Agregar Gallo',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el contenido principal del dashboard
  Widget _construirContenidoDashboard(BuildContext context) {
    return Padding(
      /// Padding generoso para escritorio
      padding: const EdgeInsets.all(32),

      child: Column(
        /// Alinear contenido a la izquierda
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          /// ==================== SECCIÓN DE ESTADÍSTICAS (KPI) ====================
          _construirSeccionEstadisticas(),

          /// Espaciador
          const SizedBox(height: 40),

          /// ==================== SECCIÓN DE LISTA RECIENTE ====================
          _construirSeccionListaReciente(),
        ],
      ),
    );
  }

  /// Construye la sección de estadísticas con tarjetas KPI
  Widget _construirSeccionEstadisticas() {
    return Consumer<GallosProveedor>(
      builder: (context, gallosProveedor, child) {
        /// Obtener estadísticas del proveedor
        final estadisticas = gallosProveedor.obtenerEstadisticas();

        return Row(
          children: [
            /// Tarjeta KPI - Gallos Activos
            TarjetaKPI(
              titulo: 'Gallos Activos',
              valor: estadisticas['activos'] ?? 0,
              colorFondo: const Color(0xFF1E3A8A).withOpacity(0.08),
              icono: FontAwesomeIcons.circleCheck,
            ),

            /// Espaciador entre tarjetas
            const SizedBox(width: 24),

            /// Tarjeta KPI - Gallos Vendidos
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

  /// Construye la sección de lista reciente de gallos
  Widget _construirSeccionListaReciente() {
    return Consumer<GallosProveedor>(
      builder: (context, gallosProveedor, child) {
        final gallos = gallosProveedor.gallosFiltrados;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Título de la sección
            Text(
              'Gallos Recientes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E3A8A),
              ),
            ),

            /// Espaciador
            const SizedBox(height: 16),

            /// Lista de gallos o mensaje vacío
            if (gallos.isEmpty)
              Container(
                /// Ancho completo
                width: double.infinity,

                /// Padding interno
                padding: const EdgeInsets.all(24),

                /// Decoración con fondo blanco
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

                /// Contenido: Mensaje de lista vacía
                child: Center(
                  child: Text(
                    'Lista de Gallos Recientes (Vacía)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8), // Gris claro
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  // Altura fija para la lista en escritorio; ajustar si hace falta
                  height: 320,
                  child: ListView.separated(
                    itemCount: gallos.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final gallo = gallos[index];
                      return TarjetaGallo(
                        gallo: gallo,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PantallaFormularioGallo(galloEditar: gallo),
                            ),
                          );
                        },
                        onDelete: () =>
                            _mostrarConfirmacionEliminar(context, gallo),
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
}
