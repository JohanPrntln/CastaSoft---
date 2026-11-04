import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:castasoft/componentes/icono_adaptativo.dart';

// Modelos y Proveedores
import 'package:castasoft/modelos/gallo_modelo.dart';
import 'package:castasoft/proveedores/gallos_proveedor.dart';

// 🔥 IMPORTANTE: Importamos la pantalla de exportar para que el botón funcione
import 'package:castasoft/pantallas/pantalla_exportar_pedigree.dart';

class PantallaDetalleGallo extends StatelessWidget {
  final Gallo gallo;

  const PantallaDetalleGallo({super.key, required this.gallo});

  // ================= UTILIDADES =================

  void _mostrarImagenGrande(BuildContext context, ImageProvider imagen) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
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

  // 🔥 LÓGICA DE EDAD (AÑOS Y MESES)
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

    if (anos == 0) return '$meses Meses';
    if (meses == 0) return '$anos Años';
    return '$anos Años, $meses m';
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Activo': return const Color(0xFF10B981);
      case 'Vendido': return const Color(0xFF6366F1);
      case 'Baja': return const Color(0xFFEF4444);
      case 'Retirado': return const Color(0xFFF59E0B);
      default: return Colors.grey;
    }
  }

  // ================= UI PRINCIPAL =================

  @override
  Widget build(BuildContext context) {
    // Nombres de padre/madre: se resuelven una vez por build vía el índice O(1)
    // del proveedor, priorizando el texto desnormalizado (RN-03).
    final gallosProv = context.read<GallosProveedor>();
    final nombrePadre = gallosProv.resolverNombrePariente(gallo.nombrePadre, gallo.padreId);
    final nombreMadre = gallosProv.resolverNombrePariente(gallo.nombreMadre, gallo.madreId);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(gallo.nombreMostrar, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white))
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // 🔥 BOTÓN: GENERAR PEDIGRÍ
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.certificate, color: Color(0xFFD4AF37)), // Icono dorado
            tooltip: 'Generar Pedigrí',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaExportarPedigree(gallo: gallo),
                ),
              );
            },
          ),

          // MENÚ DE OPCIONES
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => Navigator.pop(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 10), Text('Editar')])),
              const PopupMenuItem(value: 'eliminar', child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 10), Text('Eliminar', style: TextStyle(color: Colors.red))])),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildEncabezado(context),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildResumenRapido(),
                  const SizedBox(height: 16),
                  _buildSeccionGenealogia(nombrePadre, nombreMadre),
                  const SizedBox(height: 16),
                  _buildSeccionSaludYCombate(),
                  const SizedBox(height: 16),
                  _buildSeccionFinanzasYExtra(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado(BuildContext context) {
    // Bytes memoizados en el modelo: sin base64Decode ni E/S de disco en build().
    // (Las rutas de archivo legadas ya no se leen aquí: `File.existsSync()` era
    // E/S síncrona en el hilo de UI y lanzaba UnsupportedError en Web.)
    final bytes = gallo.fotoBytes;
    final ImageProvider? proveedorImagen = bytes != null ? MemoryImage(bytes) : null;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        children: [
          Hero(
            tag: gallo.id,
            child: GestureDetector(
              onTap: proveedorImagen != null 
                  ? () => _mostrarImagenGrande(context, proveedorImagen) 
                  : null,
              child: Container(
                width: 200, 
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [const BoxShadow(blurRadius: 15, color: Colors.black38)],
                  image: proveedorImagen != null 
                      ? DecorationImage(image: proveedorImagen, fit: BoxFit.cover) 
                      : null,
                ),
                child: proveedorImagen == null 
                    ? const FaIcon(FontAwesomeIcons.kiwiBird, size: 80, color: Colors.grey) 
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            gallo.placa, 
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18, letterSpacing: 1.5)
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              gallo.nombreMostrar,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: _colorEstado(gallo.estado),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              gallo.estado.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRapido() {
    return Row(
      children: [
        _datoCard(FontAwesomeIcons.cakeCandles, _calcularEdadBonita(gallo.fechaNacimiento), 'Edad'),
        const SizedBox(width: 10),
        _datoCard(FontAwesomeIcons.weightScale, '${gallo.pesoActual ?? "--"} Lbs', 'Peso'),
        const SizedBox(width: 10),
        _datoCard(gallo.sexo == 'Macho' ? FontAwesomeIcons.mars : FontAwesomeIcons.venus, gallo.sexo, 'Sexo'),
      ],
    );
  }

  Widget _buildSeccionGenealogia(String nombrePadre, String nombreMadre) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion('Genealogía', FontAwesomeIcons.sitemap),
            const SizedBox(height: 15),
            _filaPariente('Padre', nombrePadre, FontAwesomeIcons.mars, Colors.blue),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 5),
              child: Column(
                children: [
                   _textoAbuelo('Abuelo P: ${gallo.nombreAbueloPaterno ?? "No reg."}'),
                   _textoAbuelo('Abuela P: ${gallo.nombreAbuelaPaterna ?? "No reg."}'),
                ],
              ),
            ),
            const Divider(height: 20),
            _filaPariente('Madre', nombreMadre, FontAwesomeIcons.venus, Colors.pink),
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 5),
              child: Column(
                children: [
                   _textoAbuelo('Abuelo M: ${gallo.nombreAbueloMaterno ?? "No reg."}'),
                   _textoAbuelo('Abuela M: ${gallo.nombreAbuelaMaterna ?? "No reg."}'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _infoFila('Línea Genética', gallo.lineaGenetica),
            _infoFila('Color Pluma', gallo.colorPluma),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionSaludYCombate() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion('Salud y Combate', FontAwesomeIcons.heartPulse),
            const SizedBox(height: 15),
            _infoFila('Etapa Vida', gallo.etapaVida),
            _infoFila('Tipo Cresta', gallo.tipoCresta),
            _infoFila('Peso Combate', '${gallo.pesoCombate ?? "--"} Lbs'),
            const Divider(),
            const Text('Vacunas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            if (gallo.vacunas.isEmpty) const Text('Sin registro', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ...gallo.vacunas.map((v) => Text('• $v', style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 10),
            const Text('Récord Peleas:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
             if (gallo.peleas.isEmpty) const Text('Sin registro', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ...gallo.peleas.map((p) => Text('⚔️ $p', style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  // 🔥 AQUÍ ESTÁ EL CAMBIO IMPORTANTE: BOTÓN AZUL GENÉRICO
  Widget _buildSeccionFinanzasYExtra(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion('Información Extra', FontAwesomeIcons.circleInfo),
            const SizedBox(height: 15),
            _infoFila('Criadero Origen', gallo.criaderoOrigen),
            _infoFila('Fase Lunar Nac.', gallo.faseLunar),
            _infoFila('Jaula / Ubic.', gallo.jaula ?? 'No asignada'),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _datoFinanciero('Costo', gallo.costoAdquisicion, Colors.red.shade700),
                _datoFinanciero('Venta', gallo.precioVenta, Colors.green.shade700),
              ],
            ),
            
            // LÓGICA DEL BOTÓN DE ENLACE / VIDEO
            if (gallo.videoUrl != null && gallo.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50, // Más alto para que sea fácil de tocar
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String urlString = gallo.videoUrl!;
                    // Aseguramos que tenga https si no lo tiene
                    if (!urlString.startsWith('http')) {
                      urlString = 'https://$urlString'; 
                    }
                    final Uri url = Uri.parse(urlString);
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      // mode: LaunchMode.externalApplication abre Youtube, Telegram, Chrome, etc.
                      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        throw 'No se pudo lanzar';
                      }
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
                      );
                    }
                  },
                  // 🔥 CAMBIO DE ESTILO: AZUL CORPORATIVO Y ICONO MUNDIAL
                  icon: const Icon(Icons.language, color: Colors.white, size: 22), 
                  label: const Text('VISITAR ENLACE / VIDEO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A), // Azul CastaSoft
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            if (gallo.notas != null && gallo.notas!.isNotEmpty) ...[
              const Divider(height: 30),
              const Text('Notas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(gallo.notas!, style: const TextStyle(color: Colors.black87, height: 1.4)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _datoCard(dynamic icon, String valor, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5)],
        ),
        child: Column(
          children: [
            IconoAdaptativo(icon, color: const Color(0xFF1E3A8A), size: 20),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
  Widget _tituloSeccion(String titulo, dynamic icono) {
    return Row(
      children: [
        IconoAdaptativo(icono, size: 18, color: const Color(0xFFD4AF37)),
        const SizedBox(width: 8),
        Text(titulo, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A8A))),
      ],
    );
  }

  Widget _infoFila(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              valor, 
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaPariente(String rol, String nombre, dynamic icono, Color colorIcono) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12, 
          backgroundColor: colorIcono.withValues(alpha: 0.1), // Actualizado a withValues
          child: IconoAdaptativo(icono, size: 14, color: colorIcono),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rol, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _textoAbuelo(String texto) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _datoFinanciero(String label, double? monto, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          monto != null ? '\$${monto.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}' : '--',
          style: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
