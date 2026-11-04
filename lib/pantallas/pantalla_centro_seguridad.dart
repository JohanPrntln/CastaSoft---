import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:castasoft/proveedores/usuario_proveedor.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';
import 'package:castasoft/proveedores/cruces_proveedor.dart';
import 'package:castasoft/servicios/servicio_backup.dart';
import 'package:castasoft/servicios/deduplicacion.dart';
import 'package:castasoft/componentes/boton_limpiar_duplicados.dart';

class PantallaCentroSeguridad extends StatefulWidget {
  const PantallaCentroSeguridad({super.key});

  @override
  State<PantallaCentroSeguridad> createState() => _PantallaCentroSeguridadState();
}

class _PantallaCentroSeguridadState extends State<PantallaCentroSeguridad> {
  bool _cargandoExportacion = false;
  bool _cargandoRestauracion = false;

  // --- EXPORTAR ---
  Future<void> _generarBackupJSON() async {
    setState(() => _cargandoExportacion = true);

    try {
      // 1. Cargamos los proveedores
      final perfil = context.read<UsuarioProveedor>().perfil;
      final gallos = context.read<GallosProveedor>().gallos;
      final crucesProv = context.read<CrucesProveedor>();

      // 🔥 EL TRUCO: Si la memoria RAM está vacía porque no ha entrado a la pantalla de cruces,
      // obligamos a la app a descargarlos de Firebase en este instante.
      if (crucesProv.cruces.isEmpty) {
        await crucesProv.cargarCruces();
      }

      // Ahora sí, tomamos la lista (que ya está garantizado que tiene los 44 cruces)
      final cruces = crucesProv.cruces; 

      final String rutaGuardado = await ServicioBackup.exportarBackupJSON(
        perfil: perfil, 
        gallos: gallos,
        cruces: cruces, 
      );
      
      if (mounted) {
        // 🔥 EL TRUCO: Capturamos el mensajero en una variable ANTES de mostrar el mensaje
        final messenger = ScaffoldMessenger.of(context);
        
        messenger.showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(child: Text('¡Respaldo guardado con éxito!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Ruta: $rutaGuardado', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                const Divider(color: Colors.white30, height: 15),
                const Text(
                  '💡 Te sugerimos buscar este archivo y enviarlo a tu WhatsApp, Google Drive o correo personal para evitar perderlo si se daña el equipo.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'CERRAR', 
              textColor: Colors.white, 
              // Usamos la variable guardada en lugar del context volátil
              onPressed: () => messenger.hideCurrentSnackBar() 
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _cargandoExportacion = false);
    }
  }

  // --- RESTAURAR ---
  Future<void> _iniciarRestauracion() async {
    // 1. Advertencia Crítica al usuario antes de proceder
    final bool confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30), SizedBox(width: 10), Text('Atención')]),
        content: const Text('Vas a inyectar un archivo de respaldo en tu cuenta actual.\n\nLos registros que ya existen en este criadero se omitirán automáticamente para evitar duplicados.\n\nAsegúrate de que este archivo sea tuyo y de confianza. ¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
            child: const Text('SÍ, RESTAURAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmar) return;

    if (!mounted) return;
    // Se capturan antes de cualquier await (contexto asíncrono seguro)
    final usuarioProv = context.read<UsuarioProveedor>();
    final gallosProv = context.read<GallosProveedor>();
    final crucesProv = context.read<CrucesProveedor>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _cargandoRestauracion = true);

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final backupData = await ServicioBackup.leerArchivoRespaldo();

      // BUG-18: se compara contra los datos COMPLETOS del perfil activo; si
      // no se pueden leer, se aborta en lugar de arriesgar duplicados.
      if (!gallosProv.datosCargados) {
        throw Exception('Los ejemplares aún se están cargando. Intenta de nuevo en unos segundos.');
      }
      await crucesProv.cargarCruces(lanzarErrores: true);

      final PlanImportacion plan = await ServicioBackup.restaurarBackupJSON(
        uid: uid,
        backupData: backupData,
        gallosProv: gallosProv,
        crucesExistentes: crucesProv.cruces,
      );
      
      // 🔥 Recargamos todos los proveedores para que la pantalla principal se actualice sola
      if (mounted) {
        await usuarioProv.cargarPerfil();
        await gallosProv.cargarGallos();
        await crucesProv.cargarCruces();
        
        messenger.showSnackBar(
          SnackBar(
            content: Text(plan.mensajeResultado, style: const TextStyle(fontWeight: FontWeight.bold)),
            duration: const Duration(seconds: 6),
            backgroundColor: Colors.blue.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _cargandoRestauracion = false);
    }
  }

  // --- LIMPIAR DUPLICADOS (solo el perfil activo) ---
  Future<PlanLimpieza> _diagnosticarDuplicados() async {
    final gallosProv = context.read<GallosProveedor>();
    final crucesProv = context.read<CrucesProveedor>();
    // Lista de cruces fresca y completa: protege los vínculos genealógicos
    await crucesProv.cargarCruces(lanzarErrores: true);
    return gallosProv.planificarLimpiezaDuplicados(crucesProv.cruces);
  }

  Future<void> _eliminarDuplicados(PlanLimpieza plan) async {
    final gallosProv = context.read<GallosProveedor>();
    final crucesProv = context.read<CrucesProveedor>();
    await gallosProv.ejecutarLimpiezaDuplicados(plan);
    await crucesProv.cargarCruces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguridad y Reportes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A), 
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.circleInfo, color: Colors.blue.shade700, size: 28),
                  const SizedBox(width: 15),
                  Expanded(child: Text('Protege tu inventario. Es recomendable hacer una copia de seguridad semanalmente y guardarla en la nube.', style: TextStyle(color: Colors.blue.shade900, fontSize: 13))),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // TARJETA 1: EXPORTAR (JSON)
            _buildCardOpcion(
              titulo: 'Copia de Seguridad Completa',
              descripcion: 'Exporta un archivo técnico (.json) con todos tus gallos, cruces genéticos, fotos y perfil.',
              icono: FontAwesomeIcons.download,
              colorIcono: Colors.green.shade600,
              botonTexto: _cargandoExportacion ? 'GENERANDO...' : 'GENERAR RESPALDO',
              botonColor: Colors.green.shade700,
              cargando: _cargandoExportacion,
              onTap: _generarBackupJSON,
            ),

            const SizedBox(height: 20),

            // 🔥 TARJETA 2: IMPORTAR (NUEVA)
            _buildCardOpcion(
              titulo: 'Restaurar Criadero',
              descripcion: 'Sube un archivo .json previamente generado para cargar tu inventario en esta cuenta.',
              icono: FontAwesomeIcons.upload,
              colorIcono: Colors.orange.shade600,
              botonTexto: _cargandoRestauracion ? 'RESTAURANDO...' : 'CARGAR RESPALDO LOCAL',
              botonColor: Colors.orange.shade700,
              cargando: _cargandoRestauracion,
              onTap: _iniciarRestauracion,
            ),

            const SizedBox(height: 20),

            // TARJETA 3: LIMPIEZA DE DUPLICADOS (BUG-18)
            _buildCardOpcion(
              titulo: 'Limpiar Registros Duplicados',
              descripcion: 'Detecta copias repetidas de ejemplares y cruces en este criadero. Verás una vista previa antes de borrar. '
                  'Recomendado: genera un respaldo antes de limpiar.',
              icono: FontAwesomeIcons.broom,
              colorIcono: Colors.deepPurple.shade600,
              botonTexto: '',
              botonColor: Colors.deepPurple.shade700,
              cargando: false,
              onTap: () {},
              accion: BotonLimpiarDuplicados(
                color: Colors.deepPurple.shade700,
                diagnosticar: _diagnosticarDuplicados,
                ejecutar: _eliminarDuplicados,
              ),
            ),

            const SizedBox(height: 20),

            // TARJETA 4: REPORTE PDF
            _buildCardOpcion(
              titulo: 'Reporte de Inventario (PDF)',
              descripcion: 'Genera un documento visual con formato de tabla para imprimir.',
              icono: FontAwesomeIcons.filePdf,
              colorIcono: Colors.red.shade600,
              botonTexto: 'PRÓXIMAMENTE',
              botonColor: Colors.grey.shade600,
              cargando: false,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estamos construyendo esta función.'))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOpcion({
    required String titulo, required String descripcion, required dynamic icono, required Color colorIcono,
    required String botonTexto, required Color botonColor, required bool cargando, required VoidCallback onTap,
    Widget? accion, // reemplaza al botón estándar
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12), 
                decoration: BoxDecoration(color: colorIcono.withValues(alpha: 0.1), shape: BoxShape.circle), 
                // AQUÍ ESTÁ LA CORRECCIÓN DEL ÍCONO
                child: icono is IconData 
                    ? Icon(icono, color: colorIcono, size: 24)
                    : FaIcon(icono, color: colorIcono, size: 24)
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(titulo, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A)))),
            ],
          ),
          const SizedBox(height: 12),
          Text(descripcion, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4)),
          const SizedBox(height: 20),
          accion ?? SizedBox(
            width: double.infinity, height: 45,
            child: ElevatedButton(
              onPressed: cargando ? null : onTap,
              style: ElevatedButton.styleFrom(backgroundColor: botonColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
              child: cargando ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(botonTexto, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}